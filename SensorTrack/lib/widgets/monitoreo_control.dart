import 'dart:async';

import 'package:flutter/material.dart';

import '../core/repository_exception.dart';
import '../models/sensor_reading.dart';
import '../services/readings_repository.dart';
import 'guardar_medicion_button.dart';

/// Control **Iniciar / Detener monitoreo** (módulo 3) para la pantalla de Sensores.
///
/// Evita guardar miles de mediciones: captura una lectura de cada sensor en
/// [sensores] cada cierto intervalo (1, 5, 10 o 30 s), las acumula y las envía
/// a Supabase por lotes de [loteSize]. Se detiene solo al llegar a
/// [maxLecturas] o al salir de la pantalla. Si un envío falla, el lote se
/// conserva y se reintenta en el siguiente intervalo.
class MonitoreoControl extends StatefulWidget {
  const MonitoreoControl({
    super.key,
    required this.lecturaActual,
    this.sensores = const [SensorType.accelerometer, SensorType.gyroscope],
    this.loteSize = 10,
    this.maxLecturas = 500,
  });

  final LecturaActual lecturaActual;
  final List<SensorType> sensores;

  /// Cantidad de lecturas acumuladas que dispara un envío.
  final int loteSize;

  /// Máximo de lecturas por sesión de monitoreo.
  final int maxLecturas;

  @override
  State<MonitoreoControl> createState() => _MonitoreoControlState();
}

class _MonitoreoControlState extends State<MonitoreoControl> {
  static const _intervalos = [1, 5, 10, 30];

  final _repo = ReadingsRepository();
  final List<SensorReading> _pendientes = [];

  Timer? _timer;
  int _intervalo = 5;
  int _capturadas = 0;
  int _guardadas = 0;
  bool _enviando = false;
  String? _error;

  bool get _activo => _timer != null;

  void _iniciar() {
    setState(() {
      _capturadas = 0;
      _error = null;
      _timer = Timer.periodic(
        Duration(seconds: _intervalo),
        (_) => _capturar(),
      );
    });
  }

  void _detener() {
    _timer?.cancel();
    setState(() => _timer = null);
    _enviar();
  }

  void _capturar() {
    if (_capturadas >= widget.maxLecturas) {
      _detener();
      _mostrar(
        'Monitoreo detenido: se alcanzó el máximo de '
        '${widget.maxLecturas} lecturas.',
      );
      return;
    }
    for (final tipo in widget.sensores) {
      final lectura = widget.lecturaActual(tipo);
      if (lectura != null) {
        _pendientes.add(lectura);
        _capturadas++;
      }
    }
    setState(() {});
    if (_pendientes.length >= widget.loteSize) _enviar();
  }

  Future<void> _enviar() async {
    if (_enviando || _pendientes.isEmpty) return;
    _enviando = true;
    final lote = List.of(_pendientes);
    try {
      await _repo.insertMany(lote);
      _pendientes.removeRange(0, lote.length);
      _guardadas += lote.length;
      _error = null;
    } on RepositoryException catch (e) {
      // Solo se avisa la primera vez para no llenar la pantalla de mensajes.
      if (_error == null) _mostrar('${e.message} Se reintentará.', error: true);
      _error = e.message;
    } finally {
      _enviando = false;
      if (mounted) setState(() {});
    }
  }

  void _mostrar(String mensaje, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Envía lo que quede pendiente sin actualizar la interfaz (ya no existe).
    if (_pendientes.isNotEmpty && !_enviando) {
      _repo.insertMany(List.of(_pendientes)).catchError((_) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Monitoreo automático',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                DropdownButton<int>(
                  value: _intervalo,
                  onChanged: _activo
                      ? null
                      : (v) => setState(() => _intervalo = v ?? _intervalo),
                  items: [
                    for (final s in _intervalos)
                      DropdownMenuItem(value: s, child: Text('Cada $s s')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _activo
                ? FilledButton.tonalIcon(
                    onPressed: _detener,
                    icon: const Icon(Icons.stop),
                    label: const Text('Detener monitoreo'),
                  )
                : FilledButton.icon(
                    onPressed: _iniciar,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Iniciar monitoreo'),
                  ),
            const SizedBox(height: 8),
            Text('Guardadas en esta sesión: $_guardadas'),
            if (_pendientes.isNotEmpty)
              Text('Pendientes de envío: ${_pendientes.length}'),
            if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
      ),
    );
  }
}

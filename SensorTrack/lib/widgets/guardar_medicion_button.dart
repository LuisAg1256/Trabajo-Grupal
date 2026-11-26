import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/repository_exception.dart';
import '../models/sensor_reading.dart';
import '../services/guardar_medicion.dart';
import '../services/readings_repository.dart';

/// Devuelve la última lectura disponible de un sensor, con la hora actual en
/// `recordedAt`, o `null` si ese sensor aún no tiene datos o no está disponible.
typedef LecturaActual = SensorReading? Function(SensorType tipo);

/// Botón **Guardar medición** (módulo 3) para la pantalla de Sensores.
///
/// Permite elegir qué sensores guardar (acelerómetro, giroscopio o ambos) y
/// toma una instantánea con [lecturaActual]. El acelerómetro se guarda con la
/// función [guardarMedicion] dada por el docente (sección 9 del taller); el
/// giroscopio, con [ReadingsRepository.insert]. Maneja los errores de conexión
/// o permisos y se deshabilita mientras guarda para evitar duplicados.
///
/// Uso en `SensorsPage`:
/// ```dart
/// GuardarMedicionButton(lecturaActual: (tipo) => switch (tipo) {
///   SensorType.accelerometer => currentAccelerometerReading,
///   SensorType.gyroscope => currentGyroscopeReading,
///   _ => null,
/// })
/// ```
class GuardarMedicionButton extends StatefulWidget {
  const GuardarMedicionButton({
    super.key,
    required this.lecturaActual,
    this.sensores = const [SensorType.accelerometer, SensorType.gyroscope],
  });

  final LecturaActual lecturaActual;

  /// Sensores que el usuario puede elegir guardar.
  final List<SensorType> sensores;

  @override
  State<GuardarMedicionButton> createState() => _GuardarMedicionButtonState();
}

class _GuardarMedicionButtonState extends State<GuardarMedicionButton> {
  final _repo = ReadingsRepository();
  late Set<SensorType> _seleccionados = widget.sensores.toSet();
  bool _guardando = false;

  Future<void> _guardar() async {
    final lecturas = _seleccionados
        .map(widget.lecturaActual)
        .whereType<SensorReading>()
        .toList();
    if (lecturas.isEmpty) {
      _mostrar('No hay lecturas disponibles para guardar.', error: true);
      return;
    }

    // La función del docente usa Supabase.instance.client directamente, así que
    // se comprueba antes que Supabase esté inicializado.
    if (!ReadingsRepository.isSupabaseInitialized) {
      _mostrar(
        'Supabase no está inicializado. Configura env.json y ejecuta con '
        '--dart-define-from-file=env.json.',
        error: true,
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      for (final lectura in lecturas) {
        if (lectura.sensorType == SensorType.accelerometer) {
          // Función proporcionada por el docente (sección 9 del taller).
          await guardarMedicion(
            lectura.x!,
            lectura.y!,
            lectura.z!,
          ).timeout(const Duration(seconds: 10));
          ReadingsRepository.notificarCambios();
        } else {
          await _repo.insert(lectura);
        }
      }
      _mostrar(
        lecturas.length == 1
            ? 'Medición guardada'
            : '${lecturas.length} mediciones guardadas',
      );
    } catch (e) {
      // Errores de conexión o permisos (RLS), como pide la sección 9.
      _mostrar(RepositoryException.fromError(e).message, error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.sensores.length > 1)
          SegmentedButton<SensorType>(
            multiSelectionEnabled: true,
            segments: [
              for (final tipo in widget.sensores)
                ButtonSegment(
                  value: tipo,
                  label: Text(AppFormatters.sensorName(tipo)),
                  icon: Icon(AppFormatters.sensorIcon(tipo)),
                ),
            ],
            selected: _seleccionados,
            onSelectionChanged: _guardando
                ? null
                : (s) => setState(() => _seleccionados = s),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: _guardando
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('Guardar medición'),
        ),
      ],
    );
  }
}

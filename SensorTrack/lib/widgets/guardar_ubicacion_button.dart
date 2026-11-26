import 'package:flutter/material.dart';

import '../core/repository_exception.dart';
import '../models/sensor_reading.dart';
import '../services/readings_repository.dart';

/// Botón **Guardar ubicación** (módulo 3) para la pantalla de Ubicación.
///
/// Antes del primer guardado de la sesión pide al usuario su consentimiento
/// para almacenar la ubicación en la nube (sección 11 del documento). Está
/// deshabilitado mientras no haya una ubicación obtenida.
///
/// Uso en `LocationPage`, a partir de un `Position` de geolocator:
/// ```dart
/// GuardarUbicacionButton(
///   ubicacion: _position == null ? null : SensorReading(
///     sensorType: SensorType.gps,
///     latitude: _position!.latitude,
///     longitude: _position!.longitude,
///     accuracy: _position!.accuracy,
///     recordedAt: _position!.timestamp,
///   ),
/// )
/// ```
class GuardarUbicacionButton extends StatefulWidget {
  const GuardarUbicacionButton({super.key, required this.ubicacion});

  /// Ubicación a guardar, o `null` si aún no hay permiso o posición.
  final SensorReading? ubicacion;

  @override
  State<GuardarUbicacionButton> createState() => _GuardarUbicacionButtonState();
}

class _GuardarUbicacionButtonState extends State<GuardarUbicacionButton> {
  /// Consentimiento dado en esta sesión de la app.
  static bool _consentimiento = false;

  final _repo = ReadingsRepository();
  bool _guardando = false;

  Future<bool> _pedirConsentimiento() async {
    if (_consentimiento) return true;
    final acepta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_on_outlined),
        title: const Text('Guardar mi ubicación en la nube'),
        content: const Text(
          'SensorTrack guardará en Supabase la latitud, longitud, precisión y '
          'fecha/hora de esta captura. ¿Autorizas el almacenamiento de tu ubicación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, autorizo'),
          ),
        ],
      ),
    );
    _consentimiento = acepta ?? false;
    return _consentimiento;
  }

  Future<void> _guardar() async {
    final ubicacion = widget.ubicacion;
    if (ubicacion == null || !ubicacion.hasLocation) return;
    if (!await _pedirConsentimiento()) {
      _mostrar('No se guardó la ubicación: no autorizaste su almacenamiento.');
      return;
    }

    setState(() => _guardando = true);
    try {
      await _repo.insert(ubicacion);
      _mostrar('Ubicación guardada');
    } on RepositoryException catch (e) {
      _mostrar(e.message, error: true);
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
    final habilitado = !_guardando && (widget.ubicacion?.hasLocation ?? false);
    return FilledButton.icon(
      onPressed: habilitado ? _guardar : null,
      icon: _guardando
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
      label: const Text('Guardar ubicación'),
    );
  }
}

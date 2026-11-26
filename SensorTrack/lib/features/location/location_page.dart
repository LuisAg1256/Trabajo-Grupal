import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/formatters.dart';
import '../../models/sensor_reading.dart';
import '../../services/location_service.dart';
import '../../widgets/guardar_ubicacion_button.dart';

/// Pantalla **3. Ubicación** (Módulo 2.4).
/// Solicita consentimiento informado, gestiona permisos de GPS, muestra
/// coordenadas, precisión, fecha/hora y un mapa interactivo OpenStreetMap.
class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final LocationService _locationService = const LocationService();
  final MapController _mapController = MapController();

  Position? _currentPosition;
  LocationStatus? _status;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isTracking = false;
  bool _privacyAcceptedInSession = false;

  StreamSubscription<Position>? _positionSub;

  /// Instantánea GPS lista para ser almacenada en Supabase en el Módulo 3.
  SensorReading? get currentGpsReading {
    final pos = _currentPosition;
    if (pos == null) return null;
    return SensorReading(
      sensorType: SensorType.gps,
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      recordedAt: pos.timestamp.toUtc(),
    );
  }

  /// Diálogo informativo previo al permiso del sistema (Sección 11: privacidad).
  Future<bool> _confirmPrivacyRationale() async {
    if (_privacyAcceptedInSession) return true;

    final currentStatus = await _locationService.checkStatus();
    if (currentStatus == LocationStatus.available) {
      _privacyAcceptedInSession = true;
      return true;
    }

    if (!mounted) return false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              color: Color.fromARGB(255, 1, 169, 184),
            ),
            SizedBox(width: 8),
            Expanded(child: Text('Uso de tu ubicación')),
          ],
        ),
        content: const Text(
          'SensorTrack solicita acceso al GPS únicamente para mostrar en pantalla tus coordenadas geográficas, la precisión en metros y visualizar el punto en el mapa.\n\nNo se almacenará ninguna ubicación en la nube sin tu autorización explícita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      _privacyAcceptedInSession = true;
      return true;
    }
    return false;
  }

  Future<void> _obtainLocation() async {
    final proceed = await _confirmPrivacyRationale();
    if (!proceed) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await _locationService.ensurePermission();
      _status = status;

      if (status != LocationStatus.available) {
        setState(() {
          _isLoading = false;
          _errorMessage = _messageForStatus(status);
        });
        return;
      }

      final position = await _locationService.getCurrent();
      if (!mounted) return;

      final hadPreviousPosition = _currentPosition != null;
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      if (hadPreviousPosition) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          16.0,
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Tiempo de espera agotado al obtener señal GPS. Intenta en un lugar despejado.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudo obtener la ubicación: $e';
      });
    }
  }

  Future<void> _toggleLiveTracking() async {
    if (_isTracking) {
      await _positionSub?.cancel();
      _positionSub = null;
      setState(() => _isTracking = false);
      return;
    }

    final proceed = await _confirmPrivacyRationale();
    if (!proceed) return;

    final status = await _locationService.ensurePermission();
    if (status != LocationStatus.available) {
      setState(() {
        _status = status;
        _errorMessage = _messageForStatus(status);
      });
      return;
    }

    setState(() {
      _status = status;
      _errorMessage = null;
      _isTracking = true;
    });

    _positionSub = _locationService.track(distanceFilter: 5).listen(
      (pos) {
        if (!mounted) return;
        final hadPos = _currentPosition != null;
        setState(() => _currentPosition = pos);
        if (hadPos) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
        }
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _isTracking = false;
          _errorMessage = 'Seguimiento GPS interrumpido: $e';
        });
      },
    );
  }

  String _messageForStatus(LocationStatus status) {
    switch (status) {
      case LocationStatus.serviceDisabled:
        return 'El servicio de ubicación (GPS) del dispositivo está desactivado.';
      case LocationStatus.denied:
        return 'Permiso de ubicación denegado. Concédelo para obtener coordenadas.';
      case LocationStatus.deniedForever:
        return 'Permiso denegado permanentemente. Habilítalo desde los ajustes de la aplicación.';
      case LocationStatus.available:
        return '';
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const primaryTeal = Color.fromARGB(255, 1, 169, 184);
    final pos = _currentPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ubicación GPS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Botones de acción GPS
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _obtainLocation,
                  style: FilledButton.styleFrom(backgroundColor: primaryTeal),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(
                    _isLoading ? 'Obteniendo…' : 'Obtener ubicación',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _toggleLiveTracking,
                icon: Icon(
                  _isTracking
                      ? Icons.stop_circle_outlined
                      : Icons.directions_walk_rounded,
                ),
                label: Text(_isTracking ? 'Detener' : 'En vivo'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mensajes de error controlados con acciones directas (Módulo 2.4)
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withAlpha(90)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildRecoveryButton(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Tarjeta de datos GPS (latitud, longitud, precisión y fecha/hora)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lectura Geográfica',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isTracking)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '● En seguimiento',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 22),
                _DataRow(
                  label: 'Latitud',
                  value: pos != null
                      ? AppFormatters.coordinate(pos.latitude)
                      : 'Sin lectura',
                ),
                const SizedBox(height: 10),
                _DataRow(
                  label: 'Longitud',
                  value: pos != null
                      ? AppFormatters.coordinate(pos.longitude)
                      : 'Sin lectura',
                ),
                const SizedBox(height: 10),
                _DataRow(
                  label: 'Precisión estimada',
                  value: pos != null
                      ? '± ${pos.accuracy.toStringAsFixed(1)} m'
                      : '—',
                ),
                const SizedBox(height: 10),
                _DataRow(
                  label: 'Fecha y hora de captura',
                  value: pos != null
                      ? AppFormatters.dateTime(pos.timestamp)
                      : '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mapa interactivo OpenStreetMap con marcador (Módulo 2.4)
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: pos == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pulsa "Obtener ubicación" para visualizar tu posición en el mapa.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(pos.latitude, pos.longitude),
                      initialZoom: 16.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.utpl.sensor_track',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(pos.latitude, pos.longitude),
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.redAccent,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                      const SimpleAttributionWidget(
                        source: Text('OpenStreetMap contributors'),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // Módulo 3: Guardar ubicación en Supabase con consentimiento
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Guardar Ubicación en Nube (Módulo 3)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Antes del primer guardado se pide tu autorización para almacenar la ubicación en Supabase.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: GuardarUbicacionButton(ubicacion: currentGpsReading),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryButton() {
    if (_status == LocationStatus.serviceDisabled) {
      return OutlinedButton.icon(
        onPressed: _locationService.openLocationSettings,
        icon: const Icon(Icons.settings_outlined, size: 18),
        label: const Text('Activar ubicación'),
      );
    }
    if (_status == LocationStatus.deniedForever) {
      return OutlinedButton.icon(
        onPressed: _locationService.openAppSettings,
        icon: const Icon(Icons.app_settings_alt_outlined, size: 18),
        label: const Text('Abrir ajustes de la app'),
      );
    }
    return OutlinedButton.icon(
      onPressed: _obtainLocation,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: const Text('Reintentar'),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

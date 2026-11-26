import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../models/sensor_reading.dart';
import '../../services/sensor_service.dart';
import '../../widgets/axis_card.dart';
import '../../widgets/guardar_medicion_button.dart';
import '../../widgets/monitoreo_control.dart';

/// Pantalla **2. Sensores** (Módulo 2.2).
/// Monitorea en tiempo real el acelerómetro (m/s²), el giroscopio (rad/s) y
/// opcionalmente el magnetómetro (μT), cancelando las suscripciones en `dispose()`.
class SensorsPage extends StatefulWidget {
  const SensorsPage({super.key});

  @override
  State<SensorsPage> createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage> {
  final SensorService _sensorService = const SensorService();

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  double? _ax, _ay, _az;
  double? _gx, _gy, _gz;
  double? _mx, _my, _mz;

  bool _accelAvailable = true;
  bool _gyroAvailable = true;
  bool _magAvailable = true;
  bool _showMagnetometer = false;
  bool _isPaused = false;

  /// Historial reciente de la magnitud del acelerómetro para el mini-gráfico en vivo (~40 muestras).
  static const int _maxSamples = 40;
  final List<FlSpot> _magnitudeHistory = [];
  int _sampleIndex = 0;

  @override
  void initState() {
    super.initState();
    _startSubscriptions();
  }

  bool get _isDesktopUnsupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  void _startSubscriptions() {
    if (_isDesktopUnsupported) {
      setState(() {
        _accelAvailable = false;
        _gyroAvailable = false;
        _magAvailable = false;
      });
      return;
    }

    // 1. Suscripción al Acelerómetro
    try {
      _accelSub = _sensorService.accelerometer().listen(
        (event) {
          if (!mounted) return;
          final mag = math.sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          setState(() {
            _accelAvailable = true;
            _ax = event.x;
            _ay = event.y;
            _az = event.z;
            _magnitudeHistory.add(FlSpot(_sampleIndex.toDouble(), mag));
            _sampleIndex++;
            if (_magnitudeHistory.length > _maxSamples) {
              _magnitudeHistory.removeAt(0);
            }
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _accelAvailable = false);
        },
      );
    } catch (_) {
      _accelAvailable = false;
    }

    // 2. Suscripción al Giroscopio
    try {
      _gyroSub = _sensorService.gyroscope().listen(
        (event) {
          if (!mounted) return;
          setState(() {
            _gyroAvailable = true;
            _gx = event.x;
            _gy = event.y;
            _gz = event.z;
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _gyroAvailable = false);
        },
      );
    } catch (_) {
      _gyroAvailable = false;
    }

    // 3. Suscripción opcional al Magnetómetro
    try {
      _magSub = _sensorService.magnetometer().listen(
        (event) {
          if (!mounted) return;
          setState(() {
            _magAvailable = true;
            _mx = event.x;
            _my = event.y;
            _mz = event.z;
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _magAvailable = false);
        },
      );
    } catch (_) {
      _magAvailable = false;
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _accelSub?.pause();
        _gyroSub?.pause();
        _magSub?.pause();
      } else {
        _accelSub?.resume();
        _gyroSub?.resume();
        _magSub?.resume();
      }
    });
  }

  /// Instantánea actual del acelerómetro lista para ser guardada en el Módulo 3.
  SensorReading? get currentAccelerometerReading {
    if (_ax == null || _ay == null || _az == null) return null;
    return SensorReading(
      sensorType: SensorType.accelerometer,
      x: _ax,
      y: _ay,
      z: _az,
      recordedAt: DateTime.now().toUtc(),
    );
  }

  /// Instantánea actual del giroscopio lista para ser guardada en el Módulo 3.
  SensorReading? get currentGyroscopeReading {
    if (_gx == null || _gy == null || _gz == null) return null;
    return SensorReading(
      sensorType: SensorType.gyroscope,
      x: _gx,
      y: _gy,
      z: _gz,
      recordedAt: DateTime.now().toUtc(),
    );
  }

  /// Lectura actual del sensor pedido, usada por los controles del Módulo 3.
  SensorReading? _lecturaActual(SensorType tipo) => switch (tipo) {
    SensorType.accelerometer => currentAccelerometerReading,
    SensorType.gyroscope => currentGyroscopeReading,
    _ => null,
  };

  double? get _accelMagnitude {
    if (_ax == null || _ay == null || _az == null) return null;
    return math.sqrt(_ax! * _ax! + _ay! * _ay! + _az! * _az!);
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const primaryTeal = Color.fromARGB(255, 1, 169, 184);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monitoreo de Sensores',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _togglePause,
            tooltip: _isPaused ? 'Reanudar lectura' : 'Pausar lectura',
            icon: Icon(
              _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Controles de estado en vivo
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _togglePause,
                  icon: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  ),
                  label: Text(
                    _isPaused ? 'Reanudar lectura' : 'Pausar lectura en vivo',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text('Magnetómetro'),
                selected: _showMagnetometer,
                onSelected: (val) => setState(() => _showMagnetometer = val),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Tarjeta de Acelerómetro
          AxisCard(
            title: 'Acelerómetro',
            subtitle: 'Aceleración lineal en tiempo real (reposo Z ≈ 9.8 m/s²)',
            icon: Icons.speed_rounded,
            unit: 'm/s²',
            x: _ax,
            y: _ay,
            z: _az,
            magnitude: _accelMagnitude,
            maxScale: 20.0,
            isAvailable: _accelAvailable,
          ),
          const SizedBox(height: 16),

          // Mini-gráfico en tiempo real con fl_chart (Módulo 2.2 opcional)
          if (_accelAvailable && _magnitudeHistory.length >= 2) ...[
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
                  const Text(
                    'Magnitud en Tiempo Real (últimas muestras)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _magnitudeHistory,
                            isCurved: true,
                            color: primaryTeal,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: primaryTeal.withAlpha(35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Tarjeta de Giroscopio
          AxisCard(
            title: 'Giroscopio',
            subtitle: 'Velocidad angular de rotación en X, Y y Z',
            icon: Icons.threesixty_rounded,
            unit: 'rad/s',
            x: _gx,
            y: _gy,
            z: _gz,
            maxScale: 10.0,
            isAvailable: _gyroAvailable,
          ),
          const SizedBox(height: 16),

          // 3. Tarjeta opcional de Magnetómetro
          if (_showMagnetometer) ...[
            AxisCard(
              title: 'Magnetómetro',
              subtitle: 'Intensidad del campo magnético terrestre',
              icon: Icons.explore_rounded,
              unit: 'μT',
              x: _mx,
              y: _my,
              z: _mz,
              maxScale: 100.0,
              isAvailable: _magAvailable,
            ),
            const SizedBox(height: 16),
          ],

          // 4. Módulo 3: Guardar medición y monitoreo automático en Supabase
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
                      'Registro en Supabase (Módulo 3)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GuardarMedicionButton(lecturaActual: _lecturaActual),
                const SizedBox(height: 12),
                MonitoreoControl(lecturaActual: _lecturaActual),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

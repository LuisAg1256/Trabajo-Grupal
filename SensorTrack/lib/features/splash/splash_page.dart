import 'package:flutter/material.dart';

import '../../models/sensor_reading.dart';
import '../../services/location_service.dart';
import '../../services/readings_repository.dart';
import '../../services/sensor_service.dart';
import '../home/home_page.dart';

/// Resultado del diagnóstico inicial precargado durante el Splash.
class InitialSystemCheck {
  final bool supabaseConnected;
  final String? supabaseError;
  final Map<SensorType, bool> motionSensors;
  final LocationStatus locationStatus;

  const InitialSystemCheck({
    required this.supabaseConnected,
    this.supabaseError,
    required this.motionSensors,
    required this.locationStatus,
  });
}

/// Pantalla de presentación inicial (Módulo 1.2).
/// Muestra la identidad **SensorTrack** mientras comprueba en paralelo el
/// estado de Supabase y los sensores disponibles del dispositivo.
class SplashPage extends StatefulWidget {
  /// Permite omitir las comprobaciones asíncronas reales durante tests de widgets.
  final bool skipAsyncChecks;

  const SplashPage({super.key, this.skipAsyncChecks = false});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrapAndNavigate();
  }

  Future<void> _bootstrapAndNavigate() async {
    InitialSystemCheck? checkResult;

    if (widget.skipAsyncChecks) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      checkResult = const InitialSystemCheck(
        supabaseConnected: false,
        supabaseError: 'Credenciales pendientes en env.json',
        motionSensors: {
          SensorType.accelerometer: false,
          SensorType.gyroscope: false,
          SensorType.magnetometer: false,
        },
        locationStatus: LocationStatus.denied,
      );
    } else {
      final repo = ReadingsRepository();
      const sensorService = SensorService();
      const locationService = LocationService();

      final minDisplay = Future<void>.delayed(
        const Duration(milliseconds: 1600),
      );

      final results = await Future.wait<Object?>([
        repo.checkConnection(),
        sensorService.checkMotionSensors(),
        locationService.checkStatus(),
        minDisplay,
      ]);

      checkResult = InitialSystemCheck(
        supabaseConnected: results[0] as bool,
        supabaseError: repo.lastConnectionError,
        motionSensors: results[1] as Map<SensorType, bool>,
        locationStatus: results[2] as LocationStatus,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HomePage(initialCheck: checkResult),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color.fromARGB(255, 1, 169, 184);

    return Scaffold(
      backgroundColor: primaryTeal,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sensors_rounded,
                    size: 72,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'SensorTrack',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Monitoreo de sensores y ubicación con Supabase',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

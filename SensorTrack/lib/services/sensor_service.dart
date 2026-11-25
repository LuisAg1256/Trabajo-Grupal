import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/sensor_reading.dart';

/// Servicio de acceso a los sensores de movimiento del dispositivo mediante
/// `sensors_plus` (Módulos 1 y 2).
class SensorService {
  const SensorService();

  /// Stream en tiempo real del acelerómetro (m/s²) con intervalo adecuado para UI.
  Stream<AccelerometerEvent> accelerometer({
    Duration samplingPeriod = SensorInterval.uiInterval,
  }) {
    return accelerometerEventStream(samplingPeriod: samplingPeriod);
  }

  /// Stream en tiempo real del giroscopio (rad/s) con intervalo adecuado para UI.
  Stream<GyroscopeEvent> gyroscope({
    Duration samplingPeriod = SensorInterval.uiInterval,
  }) {
    return gyroscopeEventStream(samplingPeriod: samplingPeriod);
  }

  /// Stream opcional del magnetómetro (μT) con intervalo adecuado para UI.
  Stream<MagnetometerEvent> magnetometer({
    Duration samplingPeriod = SensorInterval.uiInterval,
  }) {
    return magnetometerEventStream(samplingPeriod: samplingPeriod);
  }

  /// Comprueba si un sensor físico emite eventos dentro del [timeout] indicado.
  /// Cancela siempre la suscripción para evitar fugas de recursos.
  Future<bool> isAvailable<T>(
    Stream<T> Function() streamBuilder, {
    Duration timeout = const Duration(milliseconds: 1200),
  }) async {
    // En plataformas de escritorio sin soporte nativo de sensors_plus evitamos excepciones no controladas.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return false;
    }

    final completer = Completer<bool>();
    StreamSubscription<T>? subscription;

    try {
      subscription = streamBuilder().listen(
        (_) {
          if (!completer.isCompleted) completer.complete(true);
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
        cancelOnError: true,
      );

      return await completer.future.timeout(timeout, onTimeout: () => false);
    } catch (_) {
      return false;
    } finally {
      await subscription?.cancel();
    }
  }

  /// Comprueba en paralelo la disponibilidad de acelerómetro, giroscopio y magnetómetro.
  Future<Map<SensorType, bool>> checkMotionSensors() async {
    final results = await Future.wait<bool>([
      isAvailable<AccelerometerEvent>(accelerometer),
      isAvailable<GyroscopeEvent>(gyroscope),
      isAvailable<MagnetometerEvent>(magnetometer),
    ]);

    return {
      SensorType.accelerometer: results[0],
      SensorType.gyroscope: results[1],
      SensorType.magnetometer: results[2],
    };
  }
}

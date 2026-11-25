import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/features/splash/splash_page.dart';
import 'package:sensor_track/models/sensor_reading.dart';

void main() {
  testWidgets('SplashPage muestra SensorTrack y navega a HomePage con 5 pestañas',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashPage(skipAsyncChecks: true)),
    );

    // Verifica que el Splash muestra el nombre de la aplicación
    expect(find.text('SensorTrack'), findsOneWidget);

    // Avanza el temporizador del Splash y estabiliza la transición a HomePage
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Verifica las 5 secciones del menú de navegación
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Sensores'), findsWidgets);
    expect(find.text('Ubicación'), findsWidgets);
    expect(find.text('Historial'), findsWidgets);
    expect(find.text('Estadísticas'), findsWidgets);
  });

  test('SensorReading serializa en UTC sin id y calcula magnitud correctamente', () {
    final now = DateTime.utc(2026, 11, 25, 14, 30);
    final reading = SensorReading(
      sensorType: SensorType.accelerometer,
      x: 3.0,
      y: 4.0,
      z: 0.0,
      recordedAt: now,
    );

    expect(reading.magnitude, closeTo(5.0, 0.001));
    final insertMap = reading.toInsertMap();
    expect(insertMap.containsKey('id'), isFalse);
    expect(insertMap['sensor_type'], 'accelerometer');
    expect(insertMap['recorded_at'], '2026-11-25T14:30:00.000Z');
  });
}

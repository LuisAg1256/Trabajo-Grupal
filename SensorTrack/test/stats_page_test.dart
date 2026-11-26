import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/features/stats/stats_page.dart';
import 'package:sensor_track/models/sensor_reading.dart';
import 'package:sensor_track/models/sensor_stats.dart';
import 'package:sensor_track/services/sensor_stats_source.dart';

void main() {
  testWidgets('muestra el resumen y permite cambiar la serie a GPS', (
    tester,
  ) async {
    final source = _FakeStatsSource(
      stats: const SensorStats(
        total: 2,
        bySensor: {'accelerometer': 1, 'gps': 1},
        accelerometer: AccelerometerStats(
          minX: -1,
          maxX: 1,
          minY: -2,
          maxY: 2,
          minZ: -3,
          maxZ: 3,
        ),
      ),
      series: {
        'accelerometer': [
          StatsSeriesPoint(
            recordedAt: DateTime.utc(2026, 1, 1),
            x: 1,
            y: 2,
            z: 3,
          ),
        ],
        'gps': [
          StatsSeriesPoint(
            recordedAt: DateTime.utc(2026, 1, 1),
            accuracy: 5,
          ),
        ],
      },
    );

    await tester.pumpWidget(MaterialApp(home: StatsPage(source: source)));
    await tester.pumpAndSettle();

    expect(find.text('Total de registros'), findsOneWidget);
    expect(find.text('Acelerómetro · máximos y mínimos'), findsOneWidget);
    expect(find.text('Última ubicación'), findsOneWidget);

    final gpsSegment = find.descendant(
      of: find.byType(SegmentedButton<SensorType>),
      matching: find.text('GPS'),
    );
    await tester.ensureVisible(gpsSegment);
    await tester.tap(gpsSegment);
    await tester.pumpAndSettle();

    expect(find.text('Precisión (m)'), findsOneWidget);
    expect(source.requestedSensors, contains('gps'));
  });

  testWidgets('muestra el estado vacío cuando no hay registros', (
    tester,
  ) async {
    final source = _FakeStatsSource(
      stats: const SensorStats(total: 0, bySensor: {}),
      series: const {},
    );

    await tester.pumpWidget(MaterialApp(home: StatsPage(source: source)));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay mediciones guardadas.'), findsOneWidget);
  });
}

class _FakeStatsSource implements SensorStatsSource {
  _FakeStatsSource({required this.stats, required this.series});

  final SensorStats stats;
  final Map<String, List<StatsSeriesPoint>> series;
  final List<String> requestedSensors = [];

  @override
  Future<SensorStats> fetchStats() async => stats;

  @override
  Future<List<StatsSeriesPoint>> fetchSeries(
    String sensorType, {
    int limit = 100,
  }) async {
    requestedSensors.add(sensorType);
    return series[sensorType] ?? const [];
  }
}

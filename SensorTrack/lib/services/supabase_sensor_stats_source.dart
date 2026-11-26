import 'dart:convert';

import '../core/repository_exception.dart';
import '../models/sensor_stats.dart';
import 'readings_repository.dart';
import 'sensor_stats_source.dart';

/// Adaptador Supabase para el contrato independiente de estadísticas.
class SupabaseSensorStatsSource implements SensorStatsSource {
  SupabaseSensorStatsSource({ReadingsRepository? repository})
    : _repository = repository ?? ReadingsRepository();

  final ReadingsRepository _repository;

  static const _timeout = Duration(seconds: 10);

  @override
  Future<SensorStats> fetchStats() {
    return _run(() async {
      final response = await _repository.client
          .rpc('sensor_stats')
          .timeout(_timeout);
      final decoded = response is String ? jsonDecode(response) : response;
      if (decoded is! Map) {
        throw const FormatException(
          'La respuesta de sensor_stats no tiene formato de objeto JSON.',
        );
      }
      return SensorStats.fromMap(Map<String, dynamic>.from(decoded));
    });
  }

  @override
  Future<List<StatsSeriesPoint>> fetchSeries(
    String sensorType, {
    int limit = 100,
  }) {
    return _run(() async {
      const sensorTypes = {
        'accelerometer',
        'gyroscope',
        'gps',
        'magnetometer',
      };
      if (!sensorTypes.contains(sensorType)) {
        throw ArgumentError.value(sensorType, 'sensorType');
      }
      if (limit < 1) {
        throw ArgumentError.value(limit, 'limit', 'Debe ser mayor que cero.');
      }

      final rows = await _repository.client
          .from(ReadingsRepository.table)
          .select('recorded_at, x, y, z, accuracy')
          .eq('sensor_type', sensorType)
          .order('recorded_at', ascending: false)
          .limit(limit)
          .timeout(_timeout);

      return rows
          .map(
            (row) => StatsSeriesPoint.fromMap(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList()
          .reversed
          .toList();
    });
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw RepositoryException.fromError(error);
    }
  }
}

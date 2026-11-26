import '../models/sensor_stats.dart';

/// Contrato modular para obtener estadísticas sin acoplar la UI a Supabase.
abstract class SensorStatsSource {
  /// Obtiene el resumen agregado de todas las mediciones.
  Future<SensorStats> fetchStats();

  /// Obtiene una serie temporal para uno de los sensores.
  Future<List<StatsSeriesPoint>> fetchSeries(
    String sensorType, {
    int limit = 100,
  });
}

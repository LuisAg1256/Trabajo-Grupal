/// Resumen estadístico usado por la pantalla de estadísticas.
class SensorStats {
  /// Cantidad total de mediciones almacenadas.
  final int total;

  /// Conteo de mediciones agrupadas por tipo de sensor.
  final Map<String, int> bySensor;

  /// Valores mínimos y máximos de las tres dimensiones del acelerómetro.
  final AccelerometerStats? accelerometer;

  /// Registro GPS más reciente disponible.
  final LocationStats? lastLocation;

  const SensorStats({
    required this.total,
    required this.bySensor,
    this.accelerometer,
    this.lastLocation,
  });

  factory SensorStats.fromMap(Map<String, dynamic> map) {
    final rawBySensor = map['by_sensor'];
    final rawAccelerometer = map['accelerometer'];
    final rawLocation = map['last_location'];

    return SensorStats(
      total: _asInt(map['total']),
      bySensor: rawBySensor is Map
          ? rawBySensor.map(
              (key, value) => MapEntry(key.toString(), _asInt(value)),
            )
          : const {},
      accelerometer: rawAccelerometer is Map
          ? AccelerometerStats.fromMap(
              Map<String, dynamic>.from(rawAccelerometer),
            )
          : null,
      lastLocation: rawLocation is Map
          ? LocationStats.fromMap(Map<String, dynamic>.from(rawLocation))
          : null,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// Minimos y maximos de cada eje del acelerómetro.
class AccelerometerStats {
  final double? minX;
  final double? maxX;
  final double? minY;
  final double? maxY;
  final double? minZ;
  final double? maxZ;

  const AccelerometerStats({
    this.minX,
    this.maxX,
    this.minY,
    this.maxY,
    this.minZ,
    this.maxZ,
  });

  factory AccelerometerStats.fromMap(Map<String, dynamic> map) {
    return AccelerometerStats(
      minX: _asDouble(map['min_x']),
      maxX: _asDouble(map['max_x']),
      minY: _asDouble(map['min_y']),
      maxY: _asDouble(map['max_y']),
      minZ: _asDouble(map['min_z']),
      maxZ: _asDouble(map['max_z']),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}

/// Datos de la ubicación registrada más recientemente.
class LocationStats {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime recordedAt;

  const LocationStats({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.recordedAt,
  });

  factory LocationStats.fromMap(Map<String, dynamic> map) {
    return LocationStats(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: map['accuracy'] is num
          ? (map['accuracy'] as num).toDouble()
          : null,
      recordedAt: DateTime.parse(map['recorded_at'].toString()).toLocal(),
    );
  }
}

/// Punto temporal utilizado para construir las series del gráfico.
class StatsSeriesPoint {
  final DateTime recordedAt;
  final double? x;
  final double? y;
  final double? z;
  final double? accuracy;

  const StatsSeriesPoint({
    required this.recordedAt,
    this.x,
    this.y,
    this.z,
    this.accuracy,
  });

  factory StatsSeriesPoint.fromMap(Map<String, dynamic> map) {
    return StatsSeriesPoint(
      recordedAt: DateTime.parse(map['recorded_at'].toString()).toLocal(),
      x: _asDouble(map['x']),
      y: _asDouble(map['y']),
      z: _asDouble(map['z']),
      accuracy: _asDouble(map['accuracy']),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}

import 'dart:math' as math;

/// Tipos de sensor admitidos en la tabla `sensor_readings`.
enum SensorType {
  accelerometer,
  gyroscope,
  gps,
  magnetometer;

  /// Convierte el valor de texto almacenado en PostgreSQL al enum correspondiente.
  static SensorType fromString(String value) {
    return SensorType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SensorType.accelerometer,
    );
  }
}

/// Modelo compartido que representa una fila de la tabla `sensor_readings`
/// en Supabase (usado transversalmente en Módulos 00 a 05).
class SensorReading {
  /// Identificador UUID generado por Supabase (nulo antes de insertar).
  final String? id;

  /// Tipo de sensor que originó la lectura.
  final SensorType sensorType;

  /// Valor del eje X (acelerómetro, giroscopio o magnetómetro).
  final double? x;

  /// Valor del eje Y (acelerómetro, giroscopio o magnetómetro).
  final double? y;

  /// Valor del eje Z (acelerómetro, giroscopio o magnetómetro).
  final double? z;

  /// Latitud geográfica en grados decimales.
  final double? latitude;

  /// Longitud geográfica en grados decimales.
  final double? longitude;

  /// Precisión estimada de la ubicación GPS en metros.
  final double? accuracy;

  /// Fecha y hora real de captura de la medición.
  final DateTime recordedAt;

  const SensorReading({
    this.id,
    required this.sensorType,
    this.x,
    this.y,
    this.z,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.recordedAt,
  });

  /// Magnitud vectorial `√(x² + y² + z²)` cuando existen los 3 ejes.
  double? get magnitude {
    if (x == null || y == null || z == null) return null;
    return math.sqrt(x! * x! + y! * y! + z! * z!);
  }

  /// Indica si el registro incluye coordenadas GPS válidas.
  bool get hasLocation => latitude != null && longitude != null;

  /// Construye un [SensorReading] a partir de un mapa devuelto por Supabase.
  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id']?.toString(),
      sensorType: SensorType.fromString(map['sensor_type']?.toString() ?? ''),
      x: (map['x'] as num?)?.toDouble(),
      y: (map['y'] as num?)?.toDouble(),
      z: (map['z'] as num?)?.toDouble(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      recordedAt: map['recorded_at'] != null
          ? DateTime.parse(map['recorded_at'].toString())
          : DateTime.now().toUtc(),
    );
  }

  /// Convierte la lectura a un mapa listo para `INSERT` en Supabase.
  /// No incluye `id` (lo genera PostgreSQL) y envía `recorded_at` en UTC.
  Map<String, dynamic> toInsertMap() {
    return {
      'sensor_type': sensorType.name,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (z != null) 'z': z,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      'recorded_at': recordedAt.toUtc().toIso8601String(),
    };
  }
}

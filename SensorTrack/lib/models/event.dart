// CREATE TABLE IF NOT EXISTS event (
//     id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//     sensor_type TEXT NOT NULL
//                 CHECK (sensor_type IN ('accelerometer')),
//     x           DOUBLE PRECISION,
//     y           DOUBLE PRECISION,
//     z           DOUBLE PRECISION,
//     recorded_at TIMESTAMPTZ DEFAULT NOW()
// );

class Event {
  final String id;
  final String sensorType;
  final double? x;
  final double? y;
  final double? z;
  final DateTime recordedAt;

  const Event({
    required this.id,
    required this.sensorType,
    this.x,
    this.y,
    this.z,
    required this.recordedAt,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as String,
      sensorType: map['sensor_type'] as String,
      x: (map['x'] as num?)?.toDouble(),
      y: (map['y'] as num?)?.toDouble(),
      z: (map['z'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'].toString()),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_reading.dart';

/// Utilidades de formato compartidas por todos los módulos (fechas, números,
/// etiquetas e íconos de sensores).
class AppFormatters {
  const AppFormatters._();

  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
  static final DateFormat _timeOnlyFormat = DateFormat('HH:mm:ss');

  /// Formatea un [DateTime] en hora local (`dd/MM/yyyy HH:mm:ss`).
  static String dateTime(DateTime dt) => _dateTimeFormat.format(dt.toLocal());

  /// Formatea solo la hora en hora local (`HH:mm:ss`).
  static String timeOnly(DateTime dt) => _timeOnlyFormat.format(dt.toLocal());

  /// Formatea un valor de eje con 2 decimales (ej. `9.81`).
  static String axis(double? value) =>
      value == null ? '—' : value.toStringAsFixed(2);

  /// Formatea una coordenada geográfica con 6 decimales.
  static String coordinate(double? value) =>
      value == null ? '—' : value.toStringAsFixed(6);

  /// Formatea un número con [decimals] decimales, o `—` si es nulo.
  static String number(double? value, [int decimals = 2]) =>
      value == null ? '—' : value.toStringAsFixed(decimals);

  /// Resumen de los ejes de una lectura, p. ej. `X: 0.12  Y: 9.80  Z: 0.03`.
  static String axes(SensorReading r) =>
      'X: ${axis(r.x)}  Y: ${axis(r.y)}  Z: ${axis(r.z)}';

  /// Coordenadas con precisión, p. ej. `-0.180530, -78.467830 (±5 m)`.
  static String location(SensorReading r) {
    final coords = '${coordinate(r.latitude)}, ${coordinate(r.longitude)}';
    return r.accuracy == null
        ? coords
        : '$coords (±${r.accuracy!.toStringAsFixed(0)} m)';
  }

  /// Resumen de los valores registrados según el tipo de sensor (Módulo 4).
  static String values(SensorReading r) =>
      r.sensorType == SensorType.gps ? location(r) : axes(r);

  /// Nombre legible en español para cada [SensorType].
  static String sensorName(SensorType type) {
    switch (type) {
      case SensorType.accelerometer:
        return 'Acelerómetro';
      case SensorType.gyroscope:
        return 'Giroscopio';
      case SensorType.gps:
        return 'GPS / Ubicación';
      case SensorType.magnetometer:
        return 'Magnetómetro';
    }
  }

  /// Unidad de medida asociada a cada [SensorType].
  static String sensorUnit(SensorType type) {
    switch (type) {
      case SensorType.accelerometer:
        return 'm/s²';
      case SensorType.gyroscope:
        return 'rad/s';
      case SensorType.gps:
        return 'grados / m';
      case SensorType.magnetometer:
        return 'μT';
    }
  }

  /// Ícono representativo para cada [SensorType].
  static IconData sensorIcon(SensorType type) {
    switch (type) {
      case SensorType.accelerometer:
        return Icons.speed_rounded;
      case SensorType.gyroscope:
        return Icons.threesixty_rounded;
      case SensorType.gps:
        return Icons.my_location_rounded;
      case SensorType.magnetometer:
        return Icons.explore_rounded;
    }
  }
}

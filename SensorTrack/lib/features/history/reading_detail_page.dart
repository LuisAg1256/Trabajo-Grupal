import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/sensor_reading.dart';

/// Pantalla de detalle de un registro individual — Estructura base para el Módulo 4.3.
/// Recibe un [SensorReading] desde `HistoryPage`.
class ReadingDetailPage extends StatelessWidget {
  final SensorReading reading;

  const ReadingDetailPage({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppFormatters.sensorName(reading.sensorType)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Detalle del registro ${reading.id ?? '(sin ID)'} — '
          'Capturado: ${AppFormatters.dateTime(reading.recordedAt)}',
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/sensor_reading.dart';

/// Ítem de la lista del Historial: tipo de sensor, valores, fecha/hora y,
/// cuando corresponde, ubicación.
class ReadingTile extends StatelessWidget {
  const ReadingTile({super.key, required this.reading, this.onTap});

  final SensorReading reading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final esGps = r.sensorType == SensorType.gps;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        child: Icon(AppFormatters.sensorIcon(r.sensorType)),
      ),
      title: Text(AppFormatters.sensorName(r.sensorType)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppFormatters.values(r)),
          // Registros de otros sensores que también llevan ubicación.
          if (!esGps && r.hasLocation) Text('📍 ${AppFormatters.location(r)}'),
          Text(
            AppFormatters.dateTime(r.recordedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

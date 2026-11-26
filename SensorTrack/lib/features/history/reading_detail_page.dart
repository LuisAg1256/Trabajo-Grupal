import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters.dart';
import '../../models/sensor_reading.dart';

/// Detalle de un registro del historial (módulo 4).
///
/// Recibe el [SensorReading] desde la lista, así que no vuelve a consultar Supabase.
class ReadingDetailPage extends StatelessWidget {
  const ReadingDetailPage({super.key, required this.reading});

  final SensorReading reading;

  void _copiar(BuildContext context, String texto, String mensaje) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final unidad = AppFormatters.sensorUnit(r.sensorType);
    final tieneEjes = r.x != null || r.y != null || r.z != null;
    final magnitud = r.magnitude;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppFormatters.sensorName(r.sensorType)),
        actions: [
          IconButton(
            tooltip: 'Copiar datos',
            icon: const Icon(Icons.copy),
            onPressed: () => _copiar(context, _comoTexto(), 'Datos copiados'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(AppFormatters.sensorIcon(r.sensorType)),
              ),
              title: Text(AppFormatters.sensorName(r.sensorType)),
              subtitle: Text(AppFormatters.dateTime(r.recordedAt)),
            ),
          ),
          if (tieneEjes)
            _Seccion(
              titulo: 'Valores registrados',
              filas: [
                ('Eje X', '${AppFormatters.number(r.x, 4)} $unidad'),
                ('Eje Y', '${AppFormatters.number(r.y, 4)} $unidad'),
                ('Eje Z', '${AppFormatters.number(r.z, 4)} $unidad'),
                if (r.sensorType == SensorType.accelerometer &&
                    magnitud != null)
                  ('Magnitud', '${AppFormatters.number(magnitud, 4)} $unidad'),
              ],
            ),
          if (r.hasLocation)
            _Seccion(
              titulo: 'Ubicación',
              filas: [
                ('Latitud', AppFormatters.number(r.latitude, 6)),
                ('Longitud', AppFormatters.number(r.longitude, 6)),
                if (r.accuracy != null)
                  ('Precisión', '±${AppFormatters.number(r.accuracy, 1)} m'),
              ],
              accion: TextButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar coordenadas'),
                onPressed: () => _copiar(
                  context,
                  '${r.latitude}, ${r.longitude}',
                  'Coordenadas copiadas',
                ),
              ),
            ),
          _Seccion(
            titulo: 'Registro',
            filas: [
              ('Tipo de sensor', r.sensorType.name),
              ('Fecha y hora', AppFormatters.dateTime(r.recordedAt)),
              ('ID', r.id ?? '—'),
            ],
          ),
        ],
      ),
    );
  }

  String _comoTexto() {
    final r = reading;
    return [
      'Sensor: ${AppFormatters.sensorName(r.sensorType)}',
      'Fecha y hora: ${AppFormatters.dateTime(r.recordedAt)}',
      if (r.x != null || r.y != null || r.z != null) AppFormatters.axes(r),
      if (r.hasLocation) 'Ubicación: ${AppFormatters.location(r)}',
      'ID: ${r.id ?? '—'}',
    ].join('\n');
  }
}

/// Tarjeta con un título y pares etiqueta / valor.
class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.filas, this.accion});

  final String titulo;
  final List<(String, String)> filas;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final (etiqueta, valor) in filas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(etiqueta, style: theme.textTheme.bodySmall),
                    ),
                    Expanded(child: SelectableText(valor)),
                  ],
                ),
              ),
            if (accion != null)
              Align(alignment: Alignment.centerRight, child: accion),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/repository_exception.dart';
import '../../models/sensor_reading.dart';
import '../../models/sensor_stats.dart';
import '../../services/sensor_stats_source.dart';
import '../../services/supabase_sensor_stats_source.dart';
import '../../widgets/readings_line_chart.dart';
import '../../widgets/stat_tile.dart';

/// Pantalla de resumen y evolución de las mediciones almacenadas.
class StatsPage extends StatefulWidget {
  const StatsPage({super.key, this.source});

  /// Fuente sustituible para pruebas y para mantener independiente la UI.
  final SensorStatsSource? source;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late final SensorStatsSource _source =
      widget.source ?? SupabaseSensorStatsSource();

  SensorStats? _stats;
  List<StatsSeriesPoint> _points = const [];
  SensorType _selectedSensor = SensorType.accelerometer;
  bool _loadingStats = true;
  bool _loadingSeries = true;
  String? _statsError;
  String? _seriesError;
  int _statsRequest = 0;
  int _seriesRequest = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final request = ++_statsRequest;
    final seriesRequest = ++_seriesRequest;
    setState(() {
      _loadingStats = true;
      _loadingSeries = true;
      _statsError = null;
      _seriesError = null;
    });

    final statsFuture = _source.fetchStats();
    final seriesFuture = _source.fetchSeries(
      _selectedSensor.name,
      limit: 100,
    );

    try {
      final stats = await statsFuture;
      if (!mounted || request != _statsRequest) return;
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } catch (error) {
      if (!mounted || request != _statsRequest) return;
      setState(() {
        _statsError = _messageFor(error);
        _loadingStats = false;
      });
    }

    try {
      final points = await seriesFuture;
      if (!mounted ||
          request != _statsRequest ||
          seriesRequest != _seriesRequest) {
        return;
      }
      setState(() {
        _points = points;
        _loadingSeries = false;
      });
    } catch (error) {
      if (!mounted ||
          request != _statsRequest ||
          seriesRequest != _seriesRequest) {
        return;
      }
      setState(() {
        _seriesError = _messageFor(error);
        _loadingSeries = false;
      });
    }
  }

  Future<void> _selectSensor(SensorType sensor) async {
    if (sensor == _selectedSensor) return;
    final request = ++_seriesRequest;
    setState(() {
      _selectedSensor = sensor;
      _loadingSeries = true;
      _seriesError = null;
    });

    try {
      final points = await _source.fetchSeries(sensor.name, limit: 100);
      if (!mounted || request != _seriesRequest) return;
      setState(() {
        _points = points;
        _loadingSeries = false;
      });
    } catch (error) {
      if (!mounted || request != _seriesRequest) return;
      setState(() {
        _seriesError = _messageFor(error);
        _loadingSeries = false;
      });
    }
  }

  String _messageFor(Object error) {
    if (error is RepositoryException) return error.message;
    return 'No fue posible cargar las estadísticas: $error';
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingStats && _stats == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estadísticas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_statsError != null && _stats == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estadísticas')),
        body: _RefreshableMessage(
          message: _statsError!,
          actionLabel: 'Reintentar',
          onAction: _refresh,
          icon: Icons.cloud_off_outlined,
        ),
      );
    }

    final stats = _stats;
    if (stats == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estadísticas')),
        body: _RefreshableMessage(
          message: 'Aún no hay mediciones guardadas.',
          onAction: _refresh,
          icon: Icons.inbox_outlined,
        ),
      );
    }

    final sensorCounts = stats.bySensor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar estadísticas',
            onPressed: _loadingStats ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_statsError != null)
              _InlineError(message: _statsError!, onRetry: _refresh),
            if (stats.total == 0)
              const _EmptyStats()
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 3 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.5,
                    children: [
                      StatTile(
                        label: 'Total de registros',
                        value: stats.total.toString(),
                        icon: Icons.analytics_outlined,
                      ),
                      ...sensorCounts.map(
                        (entry) => StatTile(
                          label: _sensorName(entry.key),
                          value: entry.value.toString(),
                          icon: _sensorIcon(entry.key),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _AccelerometerStatsCard(stats: stats.accelerometer),
              const SizedBox(height: 16),
              _LastLocationCard(location: stats.lastLocation),
              const SizedBox(height: 16),
              _SeriesCard(
                selectedSensor: _selectedSensor,
                points: _points,
                loading: _loadingSeries,
                error: _seriesError,
                onSensorSelected: _selectSensor,
                onRetry: _refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _sensorName(String name) {
    for (final type in SensorType.values) {
      if (type.name == name) return _sensorLabel(type);
    }
    return name;
  }

  static IconData _sensorIcon(String name) {
    for (final type in SensorType.values) {
      if (type.name == name) return _sensorIconFor(type);
    }
    return Icons.sensors;
  }

  static String _sensorLabel(SensorType type) {
    switch (type) {
      case SensorType.accelerometer:
        return 'Acelerómetro';
      case SensorType.gyroscope:
        return 'Giroscopio';
      case SensorType.gps:
        return 'GPS';
      case SensorType.magnetometer:
        return 'Magnetómetro';
    }
  }

  static IconData _sensorIconFor(SensorType type) {
    switch (type) {
      case SensorType.accelerometer:
        return Icons.speed;
      case SensorType.gyroscope:
        return Icons.rotate_90_degrees_ccw;
      case SensorType.gps:
        return Icons.location_on;
      case SensorType.magnetometer:
        return Icons.explore;
    }
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({
    required this.selectedSensor,
    required this.points,
    required this.loading,
    required this.error,
    required this.onSensorSelected,
    required this.onRetry,
  });

  final SensorType selectedSensor;
  final List<StatsSeriesPoint> points;
  final bool loading;
  final String? error;
  final ValueChanged<SensorType> onSensorSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolución de mediciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<SensorType>(
              segments: const [
                ButtonSegment(
                  value: SensorType.accelerometer,
                  label: Text('Acelerómetro'),
                ),
                ButtonSegment(
                  value: SensorType.gyroscope,
                  label: Text('Giroscopio'),
                ),
                ButtonSegment(value: SensorType.gps, label: Text('GPS')),
              ],
              selected: {selectedSensor},
              onSelectionChanged: (selection) {
                onSensorSelected(selection.first);
              },
            ),
            const SizedBox(height: 12),
            if (loading)
              const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              _InlineError(message: error!, onRetry: onRetry)
            else
              ReadingsLineChart(
                points: points,
                showGpsAccuracy: selectedSensor == SensorType.gps,
              ),
            if (!loading && error == null && points.isNotEmpty) ...[
              const SizedBox(height: 8),
              _Legend(selectedSensor: selectedSensor),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.selectedSensor});

  final SensorType selectedSensor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (selectedSensor == SensorType.gps) {
      return _LegendItem(color: scheme.primary, label: 'Precisión (m)');
    }
    return Wrap(
      spacing: 16,
      children: [
        _LegendItem(color: scheme.primary, label: 'X'),
        _LegendItem(color: scheme.tertiary, label: 'Y'),
        _LegendItem(color: scheme.secondary, label: 'Z'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 3, color: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _AccelerometerStatsCard extends StatelessWidget {
  const _AccelerometerStatsCard({required this.stats});

  final AccelerometerStats? stats;

  @override
  Widget build(BuildContext context) {
    final values = stats;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acelerómetro · máximos y mínimos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (values == null)
              const Text('Sin datos de acelerómetro.')
            else
              Table(
                border: TableBorder.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                children: [
                  const TableRow(
                    children: [
                      _TableCell(''),
                      _TableCell('X'),
                      _TableCell('Y'),
                      _TableCell('Z'),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _TableCell('Máximo'),
                      _NumberCell(values.maxX),
                      _NumberCell(values.maxY),
                      _NumberCell(values.maxZ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const _TableCell('Mínimo'),
                      _NumberCell(values.minX),
                      _NumberCell(values.minY),
                      _NumberCell(values.minZ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              'Unidad: m/s²',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _NumberCell extends StatelessWidget {
  const _NumberCell(this.value);

  final double? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(value == null ? '—' : value!.toStringAsFixed(2)),
    );
  }
}

class _LastLocationCard extends StatelessWidget {
  const _LastLocationCard({required this.location});

  final LocationStats? location;

  @override
  Widget build(BuildContext context) {
    final value = location;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: const Text('Última ubicación'),
        subtitle: value == null
            ? const Text('Sin ubicación registrada.')
            : Text(
                '${value.latitude.toStringAsFixed(6)}, '
                '${value.longitude.toStringAsFixed(6)}'
                '${value.accuracy == null ? '' : ' · ±${value.accuracy!.toStringAsFixed(1)} m'}'
                '\n${_formatDateTime(value.recordedAt)}',
              ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}:${twoDigits(local.second)}';
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: Text('Aún no hay mediciones guardadas.')),
    );
  }
}

class _RefreshableMessage extends StatelessWidget {
  const _RefreshableMessage({
    required this.message,
    required this.icon,
    required this.onAction,
    this.actionLabel,
  });

  final String message;
  final IconData icon;
  final Future<void> Function() onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onAction,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Center(child: Text(message, textAlign: TextAlign.center)),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            Center(
              child: FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

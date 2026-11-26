import 'package:flutter/material.dart';

import '../models/sensor_stats.dart';

/// Gráfico de evolución con selección táctil de una muestra y sus valores.
class ReadingsLineChart extends StatefulWidget {
  const ReadingsLineChart({
    super.key,
    required this.points,
    this.showGpsAccuracy = false,
  });

  final List<StatsSeriesPoint> points;
  final bool showGpsAccuracy;

  @override
  State<ReadingsLineChart> createState() => _ReadingsLineChartState();
}

class _ReadingsLineChartState extends State<ReadingsLineChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final hasValues = widget.showGpsAccuracy
        ? widget.points.any((point) => point.accuracy != null)
        : widget.points.any(
            (point) => point.x != null || point.y != null || point.z != null,
          );
    if (!hasValues) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('No hay datos para mostrar')),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final colors = [scheme.primary, scheme.tertiary, scheme.secondary];

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              const chartLeft = 44.0;
              final chartWidth = constraints.maxWidth - chartLeft - 12;
              if (chartWidth <= 0 || widget.points.isEmpty) return;
              final fraction =
                  ((details.localPosition.dx - chartLeft) / chartWidth)
                      .clamp(0.0, 1.0);
              setState(() {
                _selectedIndex =
                    (fraction * (widget.points.length - 1)).round();
              });
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, 260),
              painter: _ReadingsChartPainter(
                points: widget.points,
                showGpsAccuracy: widget.showGpsAccuracy,
                colors: colors,
                textColor: scheme.onSurface,
                gridColor: scheme.outlineVariant.withValues(alpha: 0.45),
                tooltipBackground: scheme.inverseSurface,
                tooltipForeground: scheme.onInverseSurface,
                selectedIndex: _selectedIndex,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReadingsChartPainter extends CustomPainter {
  const _ReadingsChartPainter({
    required this.points,
    required this.showGpsAccuracy,
    required this.colors,
    required this.textColor,
    required this.gridColor,
    required this.tooltipBackground,
    required this.tooltipForeground,
    required this.selectedIndex,
  });

  final List<StatsSeriesPoint> points;
  final bool showGpsAccuracy;
  final List<Color> colors;
  final Color textColor;
  final Color gridColor;
  final Color tooltipBackground;
  final Color tooltipForeground;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chart = Rect.fromLTRB(
      44,
      16,
      size.width - 12,
      size.height - 44,
    );
    if (chart.width <= 0 || chart.height <= 0) return;

    final values = <double>[
      for (final point in points)
        if (showGpsAccuracy) ...[
          if (point.accuracy != null) point.accuracy!,
        ] else ...[
          if (point.x != null) point.x!,
          if (point.y != null) point.y!,
          if (point.z != null) point.z!,
        ],
    ];
    if (values.isEmpty) return;

    var minValue = values.reduce((a, b) => a < b ? a : b);
    var maxValue = values.reduce((a, b) => a > b ? a : b);
    if (minValue == maxValue) {
      minValue -= 1;
      maxValue += 1;
    } else {
      final padding = (maxValue - minValue) * 0.08;
      minValue -= padding;
      maxValue += padding;
    }

    double xFor(int index) => points.length == 1
        ? chart.center.dx
        : chart.left + chart.width * index / (points.length - 1);
    double yFor(double value) =>
        chart.bottom - (value - minValue) / (maxValue - minValue) * chart.height;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: textColor, fontSize: 10);

    for (var tick = 0; tick <= 4; tick++) {
      final fraction = tick / 4;
      final y = chart.bottom - chart.height * fraction;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      _drawText(
        canvas,
        (minValue + (maxValue - minValue) * fraction).toStringAsFixed(1),
        Offset(0, y - 6),
        labelStyle,
        maxWidth: chart.left - 6,
        alignRight: true,
      );
    }

    void drawSeries(List<double?> series, Color color) {
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final pointPaint = Paint()..color = color;
      Offset? previous;

      for (var index = 0; index < series.length; index++) {
        final value = series[index];
        if (value == null) {
          previous = null;
          continue;
        }
        final current = Offset(xFor(index), yFor(value));
        if (previous != null) canvas.drawLine(previous, current, linePaint);
        canvas.drawCircle(current, 2.5, pointPaint);
        previous = current;
      }
    }

    if (showGpsAccuracy) {
      drawSeries(points.map((point) => point.accuracy).toList(), colors.first);
    } else {
      drawSeries(points.map((point) => point.x).toList(), colors[0]);
      drawSeries(points.map((point) => point.y).toList(), colors[1]);
      drawSeries(points.map((point) => point.z).toList(), colors[2]);
    }

    final firstLabel = _shortDate(points.first.recordedAt);
    final lastLabel = _shortDate(points.last.recordedAt);
    _drawText(
      canvas,
      firstLabel,
      Offset(chart.left, chart.bottom + 8),
      labelStyle,
      maxWidth: chart.width / 2,
    );
    _drawText(
      canvas,
      lastLabel,
      Offset(chart.right, chart.bottom + 8),
      labelStyle,
      maxWidth: chart.width / 2,
      alignRight: true,
    );

    final index = selectedIndex;
    if (index != null && index >= 0 && index < points.length) {
      _drawSelection(canvas, chart, index, xFor(index), labelStyle);
    }
  }

  void _drawSelection(
    Canvas canvas,
    Rect chart,
    int index,
    double x,
    TextStyle style,
  ) {
    final guidePaint = Paint()
      ..color = textColor.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), guidePaint);

    final point = points[index];
    final lines = <String>[
      _fullDate(point.recordedAt),
      if (showGpsAccuracy)
        'Precisión: ${_formatValue(point.accuracy)} m'
      else ...[
        'X: ${_formatValue(point.x)}',
        'Y: ${_formatValue(point.y)}',
        'Z: ${_formatValue(point.z)}',
      ],
    ];
    final text = lines.join('\n');
    final boxWidth = 172.0;
    final boxHeight = lines.length * 15.0 + 12;
    final left =
        (x - boxWidth / 2).clamp(4.0, chart.right - boxWidth).toDouble();
    final top = chart.top + 4;
    final rect = Rect.fromLTWH(left, top, boxWidth, boxHeight);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = tooltipBackground,
    );
    _drawText(
      canvas,
      text,
      Offset(rect.left + 7, rect.top + 5),
      style.copyWith(color: tooltipForeground, fontSize: 10),
      maxWidth: rect.width - 14,
    );
  }

  static String _formatValue(double? value) =>
      value == null ? '—' : value.toStringAsFixed(2);

  static String _shortDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static String _fullDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
    bool alignRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: text.contains('\n') ? 5 : 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      Offset(alignRight ? offset.dx - painter.width : offset.dx, offset.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _ReadingsChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.showGpsAccuracy != showGpsAccuracy ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.tooltipBackground != tooltipBackground ||
        oldDelegate.tooltipForeground != tooltipForeground;
  }
}

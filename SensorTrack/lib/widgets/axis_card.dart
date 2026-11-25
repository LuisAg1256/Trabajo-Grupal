import 'package:flutter/material.dart';

import '../core/formatters.dart';

/// Tarjeta reutilizable para mostrar en tiempo real los ejes X, Y y Z de un
/// sensor (acelerómetro, giroscopio o magnetómetro) con barras proporcionales.
class AxisCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String unit;
  final double? x;
  final double? y;
  final double? z;
  final double? magnitude;
  final double maxScale;
  final bool isAvailable;
  final String? unavailableMessage;

  const AxisCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.unit,
    required this.x,
    required this.y,
    required this.z,
    this.magnitude,
    this.maxScale = 20.0,
    this.isAvailable = true,
    this.unavailableMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const primaryTeal = Color.fromARGB(255, 1, 169, 184);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryTeal.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryTeal, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!isAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(90)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sensors_off_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      unavailableMessage ??
                          'Sensor no disponible en este dispositivo o plataforma.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _AxisBarRow(
              label: 'Eje X',
              value: x,
              unit: unit,
              color: Colors.indigo,
              maxScale: maxScale,
            ),
            const SizedBox(height: 10),
            _AxisBarRow(
              label: 'Eje Y',
              value: y,
              unit: unit,
              color: primaryTeal,
              maxScale: maxScale,
            ),
            const SizedBox(height: 10),
            _AxisBarRow(
              label: 'Eje Z',
              value: z,
              unit: unit,
              color: Colors.deepOrange,
              maxScale: maxScale,
            ),
            if (magnitude != null) ...[
              const Divider(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Magnitud total √(X² + Y² + Z²)',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${AppFormatters.axis(magnitude)} $unit',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AxisBarRow extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final Color color;
  final double maxScale;

  const _AxisBarRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.maxScale,
  });

  @override
  Widget build(BuildContext context) {
    final v = value ?? 0.0;
    final normalized = (v.abs() / maxScale).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              '${AppFormatters.axis(value)} $unit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 7,
            backgroundColor: color.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

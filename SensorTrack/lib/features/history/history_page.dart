import 'package:flutter/material.dart';

/// Pantalla **4. Historial** — Estructura base lista para el compañero del Módulo 4.
/// Ver especificaciones detalladas en `doc/plan/04-modulo-historial.md`.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de Mediciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history_edu_rounded,
                  size: 48,
                  color: Color.fromARGB(255, 1, 169, 184),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Módulo 4 · Historial de Mediciones',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estructura lista para conectar ReadingsRepository.fetchPage(), filtros por SensorType y navegación a ReadingDetailPage.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Pantalla **5. Estadísticas** — Estructura base lista para el compañero del Módulo 5.
/// Ver especificaciones detalladas en `doc/plan/05-modulo-estadisticas.md`.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estadísticas y Visualización',
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
                  Icons.insights_rounded,
                  size: 48,
                  color: Color.fromARGB(255, 1, 169, 184),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Módulo 5 · Estadísticas y Evolución',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estructura lista para mostrar totales, conteo por sensor, máx/mín del acelerómetro, última ubicación y LineChart con fl_chart.',
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

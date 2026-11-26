# Módulo 5 · Estadísticas y visualización

> Pantalla del documento: **5. Estadísticas** — resumen y evolución de mediciones.

## Objetivo

Resumir los datos almacenados en Supabase con indicadores y un gráfico de evolución.

## Requisitos del documento

| Requisito | Dónde se cumple |
|-----------|-----------------|
| Cantidad total de registros | Tarjeta "Total" |
| Número de mediciones por sensor | Tarjetas o gráfico de barras |
| Valores máximos y mínimos del acelerómetro | Tabla máx/mín por eje |
| Última ubicación registrada | Tarjeta con lat/lon/fecha (+ mini-mapa opcional) |
| Gráfico de evolución de las mediciones | `ReadingsLineChart` interactivo |

## Tareas

- [x] Definir `public.sensor_stats()` en [`supabase/schema.sql`](../../supabase/schema.sql).
- [x] Llamar la RPC desde `SupabaseSensorStatsSource.fetchStats()` y mapear la
  respuesta a `SensorStats`.
- [ ] Ejecutar el script actualizado en el proyecto Supabase del equipo.

### 5.2 Datos para el gráfico
- [x] En `SupabaseSensorStatsSource.fetchSeries(String sensorType, {int limit = 100})` →
  últimas N lecturas del sensor ordenadas por `recorded_at` (consultar desc + `limit`,
  luego invertir para dibujar de izquierda a derecha).

### 5.3 Pantalla — `features/stats/stats_page.dart`
- [x] Tarjetas (`StatTile`): **Total de registros** y conteo por sensor.
- [x] Tabla **Acelerómetro máx/mín** con columnas X, Y, Z (2 decimales, m/s²).
- [x] Tarjeta **Última ubicación** con lat/lon, precisión y fecha.
- [x] **Gráfico de evolución** interactivo:
  - Selector de sensor (Acelerómetro / Giroscopio / GPS).
  - 3 líneas (X, Y, Z) con colores distintos y leyenda; eje X = hora de la muestra.
  - Tooltip al tocar una muestra con valores y hora.
  - Si se elige GPS, graficar la precisión (m) en el tiempo.
- [x] `RefreshIndicator` y estados de carga / vacío / error.

> El gráfico se implementó con `CustomPainter` en `ReadingsLineChart` para
> mantener la visualización desacoplada de paquetes. El gráfico del módulo 2
> continúa usando `fl_chart`.

## Archivos

| Archivo | Acción |
|---------|--------|
| `supabase/schema.sql` | Función `sensor_stats()` añadida |
| `lib/models/sensor_stats.dart` | Nuevo |
| `lib/services/sensor_stats_source.dart` | Contrato de datos independiente |
| `lib/services/supabase_sensor_stats_source.dart` | Adaptador RPC y serie temporal |
| `lib/features/stats/stats_page.dart` | Pantalla completa |
| `lib/widgets/stat_tile.dart`, `lib/widgets/readings_line_chart.dart` | Widgets reutilizables |

## Criterios de aceptación

- [ ] El total y los conteos por sensor coinciden con `SELECT sensor_type, COUNT(*) … GROUP BY` en Supabase.
- [ ] Máx/mín del acelerómetro coinciden con `MIN/MAX` en el SQL Editor.
- [ ] La última ubicación es la del registro GPS más reciente.
- [ ] El gráfico muestra la evolución de X/Y/Z y se actualiza al refrescar tras guardar más datos.
- [ ] Con la tabla vacía, la pantalla muestra un estado vacío y no falla.

> Estos criterios quedan pendientes hasta ejecutar el SQL en Supabase y probar la
> integración con datos reales.

## Evidencias
- Captura de la pantalla de estadísticas completa.
- Captura de la consulta SQL de verificación en Supabase con los mismos números.

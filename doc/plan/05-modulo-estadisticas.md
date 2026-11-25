# Módulo 5 · Estadísticas y visualización

> Pantalla del documento: **5. Estadísticas** — gráficos y estadísticas de mediciones (`fl_chart`).

## Objetivo

Resumir los datos almacenados en Supabase con indicadores y un gráfico de evolución.

## Requisitos del documento

| Requisito | Dónde se cumple |
|-----------|-----------------|
| Cantidad total de registros | Tarjeta "Total" |
| Número de mediciones por sensor | Tarjetas o gráfico de barras |
| Valores máximos y mínimos del acelerómetro | Tabla máx/mín por eje |
| Última ubicación registrada | Tarjeta con lat/lon/fecha (+ mini-mapa opcional) |
| Gráfico de evolución de las mediciones | `LineChart` de `fl_chart` |

## Tareas

### 5.1 Cálculo en la base de datos (recomendado)
Calcular en Postgres evita descargar toda la tabla. Añadir a `supabase/schema.sql` y ejecutar:

```sql
-- Devuelve todas las estadísticas en un único JSON.
CREATE OR REPLACE FUNCTION sensor_stats()
RETURNS JSON
LANGUAGE sql
STABLE
AS $$
  SELECT json_build_object(
    'total', (SELECT COUNT(*) FROM sensor_readings),
    'by_sensor', (
      SELECT COALESCE(json_object_agg(sensor_type, n), '{}'::json)
      FROM (SELECT sensor_type, COUNT(*) AS n FROM sensor_readings GROUP BY sensor_type) t
    ),
    'accelerometer', (
      SELECT json_build_object(
        'min_x', MIN(x), 'max_x', MAX(x),
        'min_y', MIN(y), 'max_y', MAX(y),
        'min_z', MIN(z), 'max_z', MAX(z))
      FROM sensor_readings WHERE sensor_type = 'accelerometer'
    ),
    'last_location', (
      SELECT json_build_object('latitude', latitude, 'longitude', longitude,
                               'accuracy', accuracy, 'recorded_at', recorded_at)
      FROM sensor_readings
      WHERE latitude IS NOT NULL AND longitude IS NOT NULL
      ORDER BY recorded_at DESC LIMIT 1
    )
  );
$$;

GRANT EXECUTE ON FUNCTION sensor_stats() TO anon;
```
- [ ] Llamar desde Flutter: `await client.rpc('sensor_stats')` y mapear a un modelo `SensorStats`.
- [ ] Alternativa si el equipo prefiere no usar funciones SQL: consultas con
  `select('id', head: true, count: CountOption.exact)` para los conteos y cálculo de
  máx/mín en Dart sobre las lecturas del acelerómetro (aceptable con pocos datos).

### 5.2 Datos para el gráfico
- [ ] En el repositorio: `fetchSeries(SensorType type, {int limit = 100})` →
  últimas N lecturas del sensor ordenadas por `recorded_at` (consultar desc + `limit`,
  luego invertir para dibujar de izquierda a derecha).

### 5.3 Pantalla — `features/stats/stats_page.dart`
- [ ] Fila de tarjetas (`StatTile`): **Total de registros** y una por sensor con su conteo.
- [ ] Opcional: `BarChart` o `PieChart` con las mediciones por sensor.
- [ ] Tabla **Acelerómetro máx/mín** con columnas X, Y, Z (2 decimales, m/s²).
- [ ] Tarjeta **Última ubicación** con lat/lon, precisión y fecha (y mini-mapa si se usa `flutter_map`).
- [ ] **Gráfico de evolución** (`LineChart`):
  - Selector de sensor (Acelerómetro / Giroscopio).
  - 3 líneas (X, Y, Z) con colores distintos y leyenda; eje X = tiempo o índice de la muestra.
  - Tooltip al tocar un punto con valor y hora.
  - Si se elige GPS, graficar la precisión (m) en el tiempo.
- [ ] `RefreshIndicator`, estados de carga / vacío / error.

## Archivos

| Archivo | Acción |
|---------|--------|
| `supabase/schema.sql` | Añadir `sensor_stats()` |
| `lib/models/sensor_stats.dart` | Nuevo |
| `lib/services/readings_repository.dart` | `fetchStats`, `fetchSeries` |
| `lib/features/stats/stats_page.dart` | Nuevo |
| `lib/widgets/stat_tile.dart`, `lib/widgets/readings_line_chart.dart` | Nuevos |

## Criterios de aceptación

- [ ] El total y los conteos por sensor coinciden con `SELECT sensor_type, COUNT(*) … GROUP BY` en Supabase.
- [ ] Máx/mín del acelerómetro coinciden con `MIN/MAX` en el SQL Editor.
- [ ] La última ubicación es la del registro GPS más reciente.
- [ ] El gráfico muestra la evolución de X/Y/Z y se actualiza al refrescar tras guardar más datos.
- [ ] Con la tabla vacía, la pantalla muestra un estado vacío y no falla.

## Evidencias
- Captura de la pantalla de estadísticas completa.
- Captura de la consulta SQL de verificación en Supabase con los mismos números.

# Módulo 4 · Historial de mediciones

> Pantalla del documento: **4. Historial** — lista de registros recuperados desde Supabase y detalle.

## Objetivo

Consultar los registros guardados en Supabase, mostrarlos en una lista ordenada por fecha y
permitir abrir el detalle de cada uno.

## Requisitos del documento

| Requisito | Dónde se cumple |
|-----------|-----------------|
| Consultar los registros almacenados en Supabase | `ReadingsRepository.fetchPage` |
| Mostrar tipo de sensor | Ítem de lista (ícono + nombre) |
| Mostrar valores registrados | Ítem de lista (resumen) y detalle (completo) |
| Mostrar fecha y hora | Ítem de lista y detalle |
| Mostrar ubicación, cuando corresponda | Ítem/detalle de registros `gps` (o con lat/lon) |
| Seleccionar un registro para consultar sus detalles | `ReadingDetailPage` |

## Tareas

### 4.1 Consulta paginada
- [ ] En `ReadingsRepository.fetchPage`:
  ```dart
  var q = _client.from('sensor_readings').select();
  if (type != null) q = q.eq('sensor_type', type.name);
  final rows = await q.order('recorded_at', ascending: false).range(from, to);
  return rows.map(SensorReading.fromMap).toList();
  ```
- [ ] Páginas de 20 registros; cargar la siguiente al llegar al final del scroll
  (`ScrollController` o un ítem "Cargar más").

### 4.2 Pantalla Historial — `features/history/history_page.dart`
- [ ] `ListView.builder` con `ReadingTile` (`widgets/reading_tile.dart`):
  - Ícono y nombre del sensor (Acelerómetro, Giroscopio, GPS…).
  - Resumen de valores: `X: 0.12  Y: 9.80  Z: 0.03` o `-0.18053, -78.46783 (±5 m)`.
  - Fecha y hora local (`dd/MM/yyyy HH:mm:ss`).
- [ ] Filtro por tipo de sensor (`ChoiceChip`s o `SegmentedButton`: Todos / Acel. / Giro. / GPS).
- [ ] `RefreshIndicator` (deslizar para recargar).
- [ ] Estados: cargando, lista vacía ("Aún no hay mediciones guardadas"), error con "Reintentar".
- [ ] Recargar al volver a la pestaña o tras guardar una medición (callback o `Stream` simple).

### 4.3 Detalle — `features/history/reading_detail_page.dart`
- [ ] Al tocar un ítem → `Navigator.push` pasando el `SensorReading` (no hace falta reconsultar).
- [ ] Mostrar todos los campos: `id`, tipo, X/Y/Z con unidad, magnitud (acelerómetro),
  latitud, longitud, precisión, fecha/hora completa.
- [ ] Si tiene coordenadas: mini-mapa con marcador (si se usa `flutter_map`) o botón
  "Abrir en mapas" (`url_launcher` con `geo:` / Google Maps).
- [ ] Botón "Copiar" coordenadas o datos al portapapeles (opcional).

## Archivos

| Archivo | Acción |
|---------|--------|
| `lib/services/readings_repository.dart` | `fetchPage`, `fetchById` |
| `lib/features/history/history_page.dart` | Nuevo |
| `lib/features/history/reading_detail_page.dart` | Nuevo |
| `lib/widgets/reading_tile.dart` | Nuevo |
| `lib/core/formatters.dart` | Nombres de sensores, unidades y formato de fecha |

## Criterios de aceptación

- [ ] La lista muestra los registros más recientes primero, con tipo, valores y fecha/hora.
- [ ] Los registros GPS muestran la ubicación.
- [ ] El filtro por sensor funciona y la paginación carga más registros sin duplicados.
- [ ] Al tocar un registro se abre su detalle con todos los campos.
- [ ] Sin conexión se muestra un error controlado con opción de reintentar.

## Evidencias
- Captura de la lista del historial con distintos tipos de sensor.
- Captura del detalle de un registro de acelerómetro y de uno GPS.
- Comparación con las mismas filas en el *Table Editor* de Supabase.

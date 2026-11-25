# SensorTrack

Aplicación móvil en Flutter para monitoreo en tiempo real de sensores físicos (acelerómetro, giroscopio, magnetómetro) y ubicación GPS con persistencia en **Supabase**.

## Ejecución del proyecto

1. Copia el archivo de ejemplo de variables de entorno:
   ```bash
   cp env.example.json env.json
   ```
2. Coloca tu `SUPABASE_URL` y tu clave pública (`SUPABASE_KEY`) dentro de `env.json` (este archivo está ignorado en Git).
3. Ejecuta el script SQL ubicado en [`../supabase/schema.sql`](../supabase/schema.sql) en el **SQL Editor** de Supabase.
4. Lanza la aplicación pasando las variables de entorno:
   ```bash
   flutter run --dart-define-from-file=env.json
   ```

## Estado de módulos del equipo

- [x] **00 · Configuración inicial:** Dependencias, esquema SQL + RLS, `Env`, permisos Android/iOS, modelo `SensorReading` y arquitectura en capas.
- [x] **01 · Pantalla principal:** `SplashPage`, navegación `NavigationBar` (5 pestañas con `IndexedStack`), verificación de conexión a Supabase y detección de sensores disponibles.
- [x] **02 · Monitoreo de sensores:** Lectura en tiempo real de acelerómetro (`m/s²` + magnitud + mini-gráfico), giroscopio (`rad/s`), magnetómetro opcional, y GPS con consentimiento de privacidad y mapa OpenStreetMap (`flutter_map`).
- [ ] **03 · Registro en Supabase:** Completar `insert` / `insertMany` en `lib/services/readings_repository.dart` y conectar los bloques preparados al final de `SensorsPage` y `LocationPage`.
- [ ] **04 · Historial de mediciones:** Implementar `fetchPage` / `fetchById` y completar `lib/features/history/history_page.dart` y `reading_detail_page.dart`.
- [ ] **05 · Estadísticas y visualización:** Añadir RPC `sensor_stats()` en `../supabase/schema.sql` y completar `lib/features/stats/stats_page.dart`.

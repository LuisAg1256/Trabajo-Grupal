# 00 · Configuración inicial

> Base para todos los módulos. Corresponde a las secciones 5, 6, 7 y 11 del documento.

## Objetivo

Dejar el proyecto Flutter listo para trabajar: dependencias instaladas, Supabase conectado,
tabla `sensor_readings` creada con políticas RLS, permisos de plataforma configurados y la
estructura de carpetas definida.

## Requisitos del documento

- Instalar `supabase_flutter`, `sensors_plus`, `geolocator`, `fl_chart`.
- Crear cuenta y proyecto en Supabase; obtener URL y clave pública (*publishable key*).
- Crear la tabla `sensor_readings` con el script SQL indicado.
- Inicializar Supabase en `main.dart` antes de `runApp`.
- Implementar políticas RLS si se habilita el acceso a la tabla.
- Solicitar y gestionar los permisos de ubicación.

## Tareas

### 0.1 Dependencias
- [ ] Desde `SensorTrack/`:
  ```bash
  flutter pub add supabase_flutter sensors_plus geolocator fl_chart intl
  ```
  `intl` se usa para formatear fechas.
- [ ] Opcional (mapa en la pantalla de Ubicación, sin API key): `flutter pub add flutter_map latlong2`.
- [ ] Cambiar `description` en `pubspec.yaml` por una descripción real del proyecto.

### 0.2 Proyecto Supabase
- [ ] Crear el proyecto en https://supabase.com (región más cercana).
- [ ] Copiar **Project URL** y **Publishable key** (`Project Settings → API Keys`).
  **Nunca** usar ni subir la `service_role` / *secret key*.
- [ ] Ejecutar en el **SQL Editor** el script de la sección 0.3.
- [ ] Guardar el mismo script en el repositorio como `supabase/schema.sql` (es un entregable).

### 0.3 Script SQL (tabla + índices + RLS)

```sql
-- Tabla principal (estructura exigida por el documento, sección 7)
CREATE TABLE IF NOT EXISTS sensor_readings (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_type TEXT NOT NULL
                CHECK (sensor_type IN ('accelerometer', 'gyroscope', 'gps', 'magnetometer')),
    x           DOUBLE PRECISION,
    y           DOUBLE PRECISION,
    z           DOUBLE PRECISION,
    latitude    DOUBLE PRECISION,
    longitude   DOUBLE PRECISION,
    accuracy    DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para el historial (orden por fecha) y estadísticas (filtro por tipo)
CREATE INDEX IF NOT EXISTS idx_sensor_readings_recorded_at ON sensor_readings (recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_sensor_readings_type        ON sensor_readings (sensor_type);

-- Seguridad a nivel de fila (sección 11 del documento)
ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;

-- La app no tiene login: se permite leer e insertar con la clave pública (rol anon).
-- No se crean políticas de UPDATE ni DELETE, por lo que esas operaciones quedan bloqueadas.
CREATE POLICY "anon puede leer"    ON sensor_readings FOR SELECT TO anon USING (true);
CREATE POLICY "anon puede insertar" ON sensor_readings FOR INSERT TO anon WITH CHECK (true);
```

> El `CHECK` de `sensor_type` es una mejora opcional; si se añade el magnetómetro u otro sensor,
> ampliar la lista. La función de estadísticas (`sensor_stats`) se añade en el
> [módulo 5](05-modulo-estadisticas.md).

### 0.4 Credenciales fuera del código
No dejar la URL ni la clave escritas en `main.dart` (el repo es público en GitHub).

- [ ] Crear `SensorTrack/env.json` (añadirlo a `.gitignore`):
  ```json
  { "SUPABASE_URL": "https://xxxx.supabase.co", "SUPABASE_KEY": "sb_publishable_xxx" }
  ```
- [ ] Crear `SensorTrack/env.example.json` con valores vacíos (este sí se sube).
- [ ] `lib/core/env.dart`:
  ```dart
  /// Configuración leída en tiempo de compilación con --dart-define-from-file.
  class Env {
    static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
  }
  ```
- [ ] Ejecutar siempre con:
  ```bash
  flutter run --dart-define-from-file=env.json
  ```

### 0.5 Inicialización en `main.dart`
- [ ] Reemplazar la plantilla del contador:
  ```dart
  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseKey);
    runApp(const SensorTrackApp());
  }
  ```
  > En `supabase_flutter` 2.x el parámetro se llama `anonKey` y acepta la *publishable key*.
  > Si la versión instalada expone `publishableKey` (como muestra el documento), usar ese.
- [ ] Envolver la inicialización en `try/catch` para que la app arranque aunque Supabase
  falle (el estado se mostrará como "Desconectado" en el módulo 1).

### 0.6 Permisos de plataforma
**Android** — `android/app/src/main/AndroidManifest.xml` (fuera de `<application>`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```
- [ ] Importante: el manifest principal **no** trae `INTERNET` (solo el de debug), por lo que
  sin esto el APK de release no conecta con Supabase.
- [ ] Cambiar `android:label` a `SensorTrack`.

**iOS** — `ios/Runner/Info.plist`:
- [ ] `NSLocationWhenInUseUsageDescription`: "SensorTrack usa tu ubicación para registrar las coordenadas de las mediciones."
- [ ] `NSMotionUsageDescription` (acceso a sensores de movimiento).

### 0.7 Modelo compartido
- [ ] `lib/models/sensor_reading.dart` con `fromMap` / `toInsertMap`:
  ```dart
  enum SensorType { accelerometer, gyroscope, gps, magnetometer }

  class SensorReading {
    final String? id;
    final SensorType sensorType;
    final double? x, y, z, latitude, longitude, accuracy;
    final DateTime recordedAt;
    // constructor, fromMap(Map<String, dynamic>), toInsertMap()
  }
  ```
  `toInsertMap()` no envía `id` (lo genera la BD) y sí envía `recorded_at` en UTC
  (`toUtc().toIso8601String()`) para guardar la hora real de captura y no la de inserción.

### 0.8 Estructura de carpetas y limpieza
- [ ] Crear las carpetas de `lib/` descritas en el [README](README.md#arquitectura-propuesta).
- [ ] Actualizar `test/widget_test.dart` (el test del contador dejará de compilar).
- [ ] Revisar `analysis_options.yaml` y dejar `flutter analyze` en verde.

## Criterios de aceptación

- [ ] `flutter run --dart-define-from-file=env.json` arranca en un dispositivo físico.
- [ ] Insertar a mano una fila desde la app (o el SQL Editor) y verla en *Table Editor*.
- [ ] Un `UPDATE`/`DELETE` con la clave pública es rechazado (RLS activo).
- [ ] `env.json` no aparece en `git status`.

## Evidencias
- Captura del proyecto en Supabase y de la tabla `sensor_readings` creada.
- Captura de las políticas RLS en *Authentication → Policies*.

# Módulo 1 · Pantalla principal

> Pantalla del documento: **1. Inicio** — menú principal, resumen de sensores y estado de conexión.

## Objetivo

Mostrar un splash con el nombre de la app, una navegación principal entre las 5 pantallas,
el estado de la conexión con Supabase y qué sensores tiene disponibles el dispositivo.

## Requisitos del documento

| Requisito | Dónde se cumple |
|-----------|-----------------|
| Mostrar el nombre de la aplicación en el splash: **SensorTrack** | `SplashPage` |
| Presentar un menú de navegación | `HomePage` con `NavigationBar` |
| Mostrar el estado de conexión con Supabase | Tarjeta "Supabase" en Inicio |
| Mostrar los sensores disponibles en el dispositivo | Tarjeta "Sensores" en Inicio |

## Tareas

### 1.1 App y tema — `lib/app.dart`
- [ ] `SensorTrackApp` con `MaterialApp(title: 'SensorTrack', debugShowCheckedModeBanner: false)`.
- [ ] Tema Material 3 (`ColorScheme.fromSeed`) con modo claro y oscuro.
- [ ] Ruta inicial: `SplashPage`.

### 1.2 Splash — `features/splash/splash_page.dart`
- [ ] Logo/ícono + texto **SensorTrack** + subtítulo ("Monitoreo de sensores").
- [ ] Mientras se muestra (~1,5–2 s), lanzar en paralelo la comprobación de Supabase y de sensores
  para que Inicio ya tenga datos al entrar.
- [ ] Navegar con `pushReplacement` a `HomePage` (que no se pueda volver al splash).
- [ ] Opcional: splash nativo con `flutter_native_splash` para evitar la pantalla en blanco inicial.

### 1.3 Menú de navegación — `features/home/home_page.dart`
- [ ] `Scaffold` con `NavigationBar` de 5 destinos:
  Inicio · Sensores · Ubicación · Historial · Estadísticas.
- [ ] Usar `IndexedStack` para conservar el estado de cada pestaña al cambiar.
- [ ] Desde Inicio, tarjetas/botones de acceso rápido a cada sección (menú principal).

### 1.4 Estado de Supabase
- [ ] En `ReadingsRepository` crear `Future<bool> checkConnection()`:
  ```dart
  await client.from('sensor_readings').select('id').limit(1)
      .timeout(const Duration(seconds: 5));
  ```
  Devuelve `true` si responde; captura `PostgrestException`, `SocketException`, `TimeoutException`.
- [ ] Tarjeta con 3 estados: *Comprobando…* (spinner), *Conectado* (verde), *Sin conexión* (rojo + mensaje).
- [ ] Botón "Reintentar" y `RefreshIndicator` en la pantalla de Inicio.

### 1.5 Sensores disponibles
`sensors_plus` no tiene un método "¿existe el sensor?", así que se detecta escuchando el stream:

- [ ] En `SensorService` crear `Future<bool> isAvailable(Stream stream)`:
  se suscribe, espera el primer evento con `timeout` de ~1 s; si llega → disponible;
  si hay `onError` o timeout → no disponible. Cancelar la suscripción siempre.
- [ ] Comprobar: acelerómetro, giroscopio, magnetómetro (opcional).
- [ ] GPS: `Geolocator.isLocationServiceEnabled()` + `Geolocator.checkPermission()`
  (mostrar "Disponible", "Desactivado" o "Sin permiso").
- [ ] Lista con ícono ✔ / ✖ por sensor y breve descripción (tabla de la sección 3 del documento).

## Archivos

| Archivo | Acción |
|---------|--------|
| `lib/main.dart` | Reescribir (ver 00) |
| `lib/app.dart` | Nuevo |
| `lib/features/splash/splash_page.dart` | Nuevo |
| `lib/features/home/home_page.dart` | Nuevo |
| `lib/widgets/status_card.dart` | Nuevo (tarjeta reutilizable de estado) |
| `lib/services/sensor_service.dart` | Nuevo (método `isAvailable`) |
| `lib/services/readings_repository.dart` | Nuevo (método `checkConnection`) |

## Criterios de aceptación

- [ ] Al abrir la app se ve el splash con "SensorTrack" y luego Inicio.
- [ ] Se puede navegar a las 5 secciones desde la barra inferior.
- [ ] Con internet: estado "Conectado". En modo avión: "Sin conexión" sin que la app se cierre.
- [ ] En un dispositivo sin giroscopio (o emulador) se muestra como "No disponible".
- [ ] Con la ubicación desactivada, GPS aparece como "Desactivado".

## Evidencias
- Captura del splash.
- Captura de Inicio conectado y otra en modo avión.
- Captura de la lista de sensores disponibles en el dispositivo físico.

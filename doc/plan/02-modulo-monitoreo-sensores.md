# Módulo 2 · Monitoreo de sensores

> Pantallas del documento: **2. Sensores** (acelerómetro y giroscopio en tiempo real) y
> **3. Ubicación** (coordenadas, precisión y mapa opcional). Secciones 3, 4 y 8 del documento.

## Objetivo

Visualizar en tiempo real los datos del acelerómetro, del giroscopio y del GPS, gestionando
permisos y la falta de sensores. Con esto se cubren los **3 sensores mínimos** exigidos.

## Requisitos del documento

| Requisito | Dónde se cumple |
|-----------|-----------------|
| Acelerómetro: ejes X, Y, Z en tiempo real | `SensorsPage` |
| Giroscopio: rotación X, Y, Z; comprobar al girar el dispositivo | `SensorsPage` |
| GPS: latitud, longitud, precisión y fecha/hora de captura | `LocationPage` |
| Mostrar la ubicación en la interfaz y, opcionalmente, en un mapa | `LocationPage` (+ `flutter_map`) |
| Cancelar la suscripción al stream en `dispose()` | `SensorsPage` |
| Controlar errores cuando un sensor no esté disponible | Ambas pantallas |
| Solicitar y gestionar permisos de ubicación | `LocationService` |

## Tareas

### 2.1 Servicio de sensores — `services/sensor_service.dart`
- [ ] Exponer streams con frecuencia controlada (evita redibujar cientos de veces por segundo):
  ```dart
  Stream<AccelerometerEvent> accelerometer() =>
      accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval);
  Stream<GyroscopeEvent> gyroscope() =>
      gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval);
  ```
- [ ] Opcional: `magnetometerEventStream()` como 4.º sensor (orientación / brújula).

### 2.2 Pantalla Sensores — `features/sensors/sensors_page.dart`
- [ ] `StatefulWidget` con dos `StreamSubscription` (acelerómetro y giroscopio) creadas en
  `initState` y **canceladas en `dispose()`** (mejora pedida en la sección 8).
- [ ] Manejar `onError` de cada stream → mostrar tarjeta "Sensor no disponible".
- [ ] Widget reutilizable `AxisCard` (`widgets/axis_card.dart`): título, unidad y valores X/Y/Z
  con 2 decimales; opcionalmente una barra por eje para ver el movimiento.
  - Acelerómetro en **m/s²**; giroscopio en **rad/s**.
- [ ] Mostrar también la magnitud `√(x²+y²+z²)` del acelerómetro (útil para "detectar movimiento").
- [ ] Botón **Pausar / Reanudar** la lectura en vivo (`subscription.pause()/resume()`).
- [ ] Opcional: mini-gráfico en vivo de los últimos ~50 valores con `fl_chart`.
- [ ] Dejar sitio para los controles del módulo 3 (botón *Guardar medición* y monitoreo automático).

### 2.3 Servicio de ubicación — `services/location_service.dart`
- [ ] `Future<LocationStatus> ensurePermission()`:
  1. `Geolocator.isLocationServiceEnabled()` → si no, estado `serviceDisabled`.
  2. `checkPermission()`; si `denied` → `requestPermission()`.
  3. Si `deniedForever` → estado `deniedForever` (ofrecer `Geolocator.openAppSettings()`).
- [ ] `Future<Position> getCurrent()` con `LocationSettings(accuracy: LocationAccuracy.high)`
  y `timeLimit` de ~15 s.
- [ ] Opcional: `Stream<Position> track()` con `getPositionStream(distanceFilter: 5)` para
  seguimiento en vivo.

### 2.4 Pantalla Ubicación — `features/location/location_page.dart`
- [ ] Antes de pedir el permiso del sistema, mostrar un diálogo propio explicando para qué se usa
  la ubicación (consideración de privacidad, sección 11).
- [ ] Mostrar: **latitud**, **longitud** (6 decimales), **precisión** (m) y **fecha/hora** de captura
  (`position.timestamp`, formateada con `intl`).
- [ ] Botón "Obtener ubicación" + estado de carga.
- [ ] Estados de error con acción: servicio desactivado → `openLocationSettings()`;
  permiso denegado para siempre → `openAppSettings()`; timeout → "Reintentar".
- [ ] **Mapa opcional**: `FlutterMap` con teselas de OpenStreetMap y un `Marker` en la posición
  (no requiere API key). Incluir la atribución de OSM.

## Archivos

| Archivo | Acción |
|---------|--------|
| `lib/services/sensor_service.dart` | Ampliar (streams) |
| `lib/services/location_service.dart` | Nuevo |
| `lib/features/sensors/sensors_page.dart` | Nuevo |
| `lib/features/location/location_page.dart` | Nuevo |
| `lib/widgets/axis_card.dart` | Nuevo |

## Criterios de aceptación

- [ ] En un dispositivo físico, al mover el teléfono cambian X/Y/Z del acelerómetro;
  en reposo sobre la mesa Z ≈ 9,8 m/s².
- [ ] Al girar el teléfono cambian los valores del giroscopio; en reposo ≈ 0.
- [ ] Al salir de la pantalla las suscripciones se cancelan (sin `setState() called after dispose`).
- [ ] Se obtiene latitud, longitud, precisión y hora; coinciden aproximadamente con Google Maps.
- [ ] Negar el permiso de ubicación no rompe la app y muestra cómo habilitarlo.

## Evidencias
- Video corto o capturas moviendo/girando el dispositivo con los valores cambiando.
- Captura de la pantalla de Ubicación con coordenadas (y mapa si se implementa).
- Captura del diálogo de permiso de ubicación.

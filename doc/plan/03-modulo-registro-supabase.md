# Módulo 3 · Registro de información en Supabase

> Secciones 4 (Módulo 3), 9 y 11 del documento. Se integra en las pantallas **Sensores** y **Ubicación**.

## Objetivo

Guardar en la tabla `sensor_readings` las mediciones del acelerómetro, giroscopio y GPS con su
fecha y hora, controlando la frecuencia de captura y los errores de conexión o permisos, y
ofrecer las consultas que usarán Historial y Estadísticas.

## Requisitos del documento

| Requisito | Dónde se cumple |
|-----------|-----------------|
| Configurar proyecto Supabase y conectar Flutter | [00-configuracion-inicial](00-configuracion-inicial.md) |
| Registrar valores del acelerómetro y del giroscopio | `ReadingsRepository.insert` + botón |
| Registrar coordenadas GPS y precisión | `ReadingsRepository.insert` desde Ubicación |
| Guardar fecha y hora de cada captura | `recorded_at` |
| Consultar los registros almacenados | `ReadingsRepository.fetch…` |
| Visualizar el historial de mediciones | [Módulo 4](04-modulo-historial.md) |
| Botón **Guardar medición** integrado con el módulo de sensores | `SensorsPage`, `LocationPage` |
| Manejar errores de conexión o permisos | `try/catch` + `SnackBar` |
| Evitar miles de mediciones: frecuencia o iniciar/detener monitoreo | Monitoreo automático |
| No almacenar ubicación sin autorización del usuario | Consentimiento explícito |

## Tareas

### 3.1 Repositorio — `services/readings_repository.dart`
Evolución de la función `guardarMedicion` del documento (sección 9) a una clase reutilizable:

```dart
/// Acceso a la tabla sensor_readings de Supabase.
class ReadingsRepository {
  final SupabaseClient _client = Supabase.instance.client;
  static const _table = 'sensor_readings';

  Future<void> insert(SensorReading r) =>
      _client.from(_table).insert(r.toInsertMap());

  Future<void> insertMany(List<SensorReading> rs) =>
      _client.from(_table).insert(rs.map((r) => r.toInsertMap()).toList());

  Future<List<SensorReading>> fetchPage({int from = 0, int to = 19, SensorType? type});
  Future<SensorReading?> fetchById(String id);
  Future<bool> checkConnection(); // usado en el módulo 1
}
```
- [ ] Todas las llamadas con `.timeout(...)`.
- [ ] Convertir excepciones (`PostgrestException`, `SocketException`, `TimeoutException`,
  `AuthException`) en una excepción propia `RepositoryException` con mensaje en español
  ("Sin conexión a internet", "Permiso denegado por la base de datos (RLS)", etc.).

### 3.2 Botón *Guardar medición* — pantalla Sensores
- [ ] Toma una **instantánea** del último valor recibido de cada sensor.
- [ ] Opción de qué guardar: acelerómetro, giroscopio o ambos (2 filas, una por `sensor_type`).
- [ ] Deshabilitar el botón mientras guarda (evita duplicados por doble toque) y mostrar spinner.
- [ ] `SnackBar` de éxito ("Medición guardada") o de error con el mensaje de `RepositoryException`.
- [ ] Opcional: adjuntar la última ubicación conocida si el usuario ya autorizó la ubicación.

### 3.3 Guardar ubicación — pantalla Ubicación
- [ ] Botón **Guardar ubicación**: inserta fila `sensor_type = 'gps'` con `latitude`,
  `longitude`, `accuracy` y `recorded_at = position.timestamp`.
- [ ] Solo habilitado si hay permiso **y** el usuario aceptó el consentimiento
  "Guardar mi ubicación en la nube" (switch o diálogo; recordar la decisión en la sesión
  o con `shared_preferences`).

### 3.4 Monitoreo automático con frecuencia controlada
- [ ] En Sensores: switch/botón **Iniciar / Detener monitoreo** y selector de intervalo
  (1 s, 5 s, 10 s, 30 s).
- [ ] Implementación: `Timer.periodic(intervalo)` que en cada tick toma la instantánea actual
  y la añade a un buffer; cada N lecturas (p. ej. 10) o al detener, envía el lote con `insertMany`.
- [ ] Mostrar contador de "mediciones guardadas en esta sesión".
- [ ] Detener automáticamente al salir de la pantalla (`dispose`) y opcionalmente al llegar a un
  máximo (p. ej. 500 lecturas) para no llenar la tabla.
- [ ] Si un envío falla: conservar el lote en memoria, avisar y reintentar en el siguiente tick.

### 3.5 Hora de captura
- [ ] Enviar siempre `recorded_at` desde el dispositivo en UTC (`DateTime.now().toUtc()` o
  `position.timestamp`), para que la hora corresponda a la captura y no al momento del envío
  (importante en el envío por lotes).
- [ ] Al mostrar, convertir a hora local (`toLocal()`).

## Archivos

| Archivo | Acción |
|---------|--------|
| `lib/services/readings_repository.dart` | Completar |
| `lib/core/repository_exception.dart` | Nuevo |
| `lib/features/sensors/sensors_page.dart` | Añadir botón y monitoreo |
| `lib/features/location/location_page.dart` | Añadir botón y consentimiento |

## Criterios de aceptación

- [ ] Pulsar *Guardar medición* crea la(s) fila(s) correcta(s) en Supabase con X/Y/Z y hora.
- [ ] Guardar ubicación crea una fila `gps` con lat/lon/precisión.
- [ ] Con monitoreo a 5 s durante 1 min se guardan ~12 lecturas por sensor, no cientos.
- [ ] En modo avión, guardar muestra un error claro y la app no se cierra.
- [ ] Sin aceptar el consentimiento no se guarda ninguna ubicación.

## Evidencias
- Captura de la app tras guardar (SnackBar de éxito).
- Captura del *Table Editor* de Supabase con filas de `accelerometer`, `gyroscope` y `gps`.
- Captura del error controlado sin conexión.

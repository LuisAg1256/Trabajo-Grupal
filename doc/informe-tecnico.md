# Informe técnico — SensorTrack

## 1. Resumen

SensorTrack es una aplicación móvil construida con Flutter para observar datos
del acelerómetro y giroscopio, consultar la ubicación GPS y registrar lecturas en
Supabase. La solución separa la interfaz, el acceso a sensores, los modelos y el
acceso a datos para que cada módulo pueda evolucionar sin incorporar sus detalles
internos a las demás pantallas.

El proyecto está organizado para que la pantalla Inicio exponga el estado
general, las pantallas de sensores presenten datos en tiempo real, el Historial
consulte lecturas persistidas y Estadísticas resuma los registros. La
configuración de credenciales se suministra en tiempo de compilación y no se
almacena en el código fuente.

## 2. Arquitectura y flujo de datos

La aplicación usa Flutter Material 3 y una arquitectura sencilla por capas:

- **Presentación:** `lib/features/` contiene Splash, Inicio, Sensores,
  Ubicación, Historial y Estadísticas.
- **Componentes reutilizables:** `lib/widgets/` contiene tarjetas de ejes y
  estados, controles de guardado y monitoreo, elementos de historial y gráfico.
- **Modelos:** `lib/models/` representa una lectura y los resultados
  estadísticos.
- **Servicios:** `lib/services/` encapsula los streams de sensores, permisos y
  posición GPS, inserciones/consultas y la fuente de estadísticas.
- **Configuración transversal:** `lib/core/` contiene variables de entorno,
  formato de valores/fechas y traducción de errores de persistencia.
- **Persistencia:** `supabase/schema.sql` define la tabla y la función RPC.

Flujo normal de una lectura:

```text
Sensor físico o GPS
        ↓
SensorService / LocationService
        ↓
Pantalla de captura → SensorReading
        ↓
ReadingsRepository → Supabase / sensor_readings
        ↓
Historial y SensorStatsSource → Estadísticas
```

La UI de estadísticas consume el contrato `SensorStatsSource`. El adaptador
`SupabaseSensorStatsSource` implementa ese contrato por separado; así los
widgets pueden probarse con una fuente falsa y el resto de la aplicación no
necesita conocer cómo se ejecuta la RPC.

## 3. Captura de sensores y ubicación

El acelerómetro informa los ejes X/Y/Z en m/s² y la pantalla presenta además la
magnitud vectorial cuando existen los tres ejes. El giroscopio informa velocidad
angular en rad/s. El magnetómetro es opcional y sus valores se expresan en μT.
Las suscripciones se cancelan al salir de la pantalla.

La ubicación se obtiene a través de `geolocator`. La aplicación debe explicar
por qué solicita el permiso antes de pedirlo al sistema. La pantalla muestra
latitud, longitud, precisión y fecha de captura, con un mapa OpenStreetMap. El
seguimiento continuo usa un filtro de distancia; el registro de la ubicación en
la nube requiere una autorización de almacenamiento separada.

Las lecturas se representan con `SensorReading`. Los valores de sensor y
coordenadas se mantienen opcionales para permitir filas de tipos distintos. El
modelo serializa su fecha de captura en UTC y la interfaz la presenta en hora
local. El botón **Guardar medición** guarda el acelerómetro con la función
`guardarMedicion(x, y, z)` proporcionada por el docente (sección 9 del taller),
que se mantiene sin modificaciones en `lib/services/guardar_medicion.dart`.
Esa función no envía `recorded_at`, por lo que la fecha la asigna la base de
datos (`DEFAULT NOW()`) al recibir la fila; el botón añade alrededor de la
llamada el manejo de errores de conexión o permisos que pide el taller.

## 4. Persistencia y base de datos

La tabla `sensor_readings` usa un UUID como identificador, `sensor_type` para
distinguir acelerómetro, giroscopio, GPS y magnetómetro, campos numéricos para
ejes/coordenadas/precisión y `recorded_at` para la fecha de captura. Los índices
por tipo y fecha apoyan consultas del historial y series temporales.

El esquema activa Row Level Security y define permisos/políticas para las
operaciones que requiere la aplicación sin autenticación. La función
`sensor_stats()` reúne en un JSON:

1. El total de filas visibles.
2. El conteo agrupado por tipo de sensor.
3. Mínimo y máximo de X/Y/Z del acelerómetro.
4. La ubicación GPS más reciente con coordenadas.

El adaptador solicita esa función para el resumen y consulta hasta 100 filas
recientes del sensor seleccionado para el gráfico, ordenándolas cronológicamente
antes de presentarlas. Las operaciones tienen límite de espera y sus fallos se
convierten en mensajes de repositorio en español.

El esquema concede lectura e inserción al rol `anon`; por ello, la clave pública
no debe confundirse con un mecanismo de autorización. Antes de usar datos
personales fuera de una demostración académica, el equipo debe definir
autenticación, límites y políticas que restrinjan quién puede leer e insertar.

## 5. Estadísticas y visualización

El módulo 5 presenta el total de registros y el conteo por sensor en tarjetas.
Una tabla muestra mínimos y máximos por eje del acelerómetro con dos decimales y
unidad m/s². Otra tarjeta informa la última ubicación, precisión y fecha cuando
existe.

El gráfico permite seleccionar acelerómetro, giroscopio o GPS. Para los dos
primeros dibuja X/Y/Z con colores diferenciados; para GPS representa la
precisión. Al tocar una muestra, muestra fecha y valores de esa lectura. Los
extremos del eje temporal se etiquetan para identificar el intervalo. La
pantalla incluye carga, error con reintento, estado sin registros y actualización
por gesto.

## 6. Privacidad, errores y limitaciones

El archivo `env.json` contiene URL y clave pública local y se excluye de Git; se
crea a partir de `env.example.json`. Nunca se debe incluir una clave
`service_role` en la aplicación. La ubicación solo debe insertarse tras obtener
consentimiento explícito. Los permisos de plataforma deben seguir limitados al
uso necesario.

Los errores de Supabase se traducen a mensajes comprensibles para la interfaz.
La disponibilidad de sensores depende del dispositivo físico; los emuladores o
plataformas de escritorio pueden no exponerlos. El mapa requiere conexión para
descargar teselas.

## 7. Validación y estado de entrega

La validación de aceptación pendiente consiste en:

- Comparar total y conteos con consultas SQL en Supabase.
- Comparar mínimos/máximos con `MIN`/`MAX` por eje.
- Confirmar que la última ubicación corresponde a la fila GPS más reciente.
- Confirmar que el gráfico se actualiza tras guardar nuevas lecturas.
- Probar tabla vacía, falta de conexión, permisos denegados y dispositivo físico.
- Ejecutar las pruebas automatizadas y el análisis estático con una versión de
  Flutter cuyo Dart SDK satisfaga `pubspec.yaml`.

No se incluyen aquí resultados de ejecución no realizados. Las capturas y el
video de demostración se deben agregar en [`evidencias/`](evidencias/README.md)
después de probar la aplicación en el dispositivo y proyecto Supabase del equipo.

## 8. Equipo

Integrantes: **completar con los nombres del grupo antes de la entrega**.

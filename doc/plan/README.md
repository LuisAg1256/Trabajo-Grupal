# Plan de implementación — SensorTrack

Plan de trabajo para implementar todo lo que pide el documento
[`Taller_SensorTrack_Flutter_Sensores_Supabase.docx`](../Taller_SensorTrack_Flutter_Sensores_Supabase.docx),
partiendo de la aplicación Flutter en [`SensorTrack/`](../../SensorTrack). Los
checklists de cada módulo distinguen el código implementado de lo que aún requiere
integración con Supabase, pruebas en dispositivo o evidencia.

## Índice

| # | Archivo | Contenido | Pantalla(s) |
|---|---------|-----------|-------------|
| 0 | [00-configuracion-inicial.md](00-configuracion-inicial.md) | Dependencias, proyecto Supabase, tabla + RLS, permisos, estructura de carpetas | — |
| 1 | [01-modulo-pantalla-principal.md](01-modulo-pantalla-principal.md) | Splash, menú de navegación, estado de Supabase, sensores disponibles | Inicio |
| 2 | [02-modulo-monitoreo-sensores.md](02-modulo-monitoreo-sensores.md) | Acelerómetro, giroscopio y GPS en tiempo real | Sensores, Ubicación |
| 3 | [03-modulo-registro-supabase.md](03-modulo-registro-supabase.md) | Guardar mediciones, botón *Guardar medición*, monitoreo con frecuencia, errores | Sensores, Ubicación |
| 4 | [04-modulo-historial.md](04-modulo-historial.md) | Lista de registros desde Supabase y pantalla de detalle | Historial |
| 5 | [05-modulo-estadisticas.md](05-modulo-estadisticas.md) | Totales, conteo por sensor, máx/mín, última ubicación, gráfico | Estadísticas |
| 6 | [06-entregables-finales.md](06-entregables-finales.md) | Documentación, evidencias, script SQL, informe técnico, demo | — |

Cada módulo tiene la misma estructura: **objetivo → requisitos del documento → tareas
(checklist) → archivos → notas técnicas → criterios de aceptación → evidencias**.

## Arquitectura propuesta

Arquitectura sencilla en capas, sin gestor de estado externo (basta con `StatefulWidget`
y `StreamBuilder`/`FutureBuilder`; si el equipo lo prefiere se puede usar `ChangeNotifier`).

```
lib/
├── main.dart                     # Inicializa Supabase y lanza la app
├── app.dart                      # MaterialApp, tema y rutas
├── core/
│   ├── env.dart                  # URL y clave de Supabase (vía --dart-define)
│   └── formatters.dart           # Formato de fechas y números
├── models/
│   ├── sensor_reading.dart       # Modelo de la tabla sensor_readings
│   └── sensor_stats.dart         # Resumen, máximos/mínimos y puntos de serie
├── services/
│   ├── sensor_service.dart       # Streams de acelerómetro / giroscopio (+ disponibilidad)
│   ├── location_service.dart     # Permisos y lectura GPS (geolocator)
│   ├── readings_repository.dart  # Inserciones e historial en Supabase
│   ├── sensor_stats_source.dart # Contrato independiente para estadísticas
│   └── supabase_sensor_stats_source.dart # RPC y consultas de series temporales
├── features/
│   ├── splash/splash_page.dart
│   ├── home/home_page.dart       # Shell con NavigationBar + pestaña Inicio
│   ├── sensors/sensors_page.dart
│   ├── location/location_page.dart
│   ├── history/history_page.dart
│   ├── history/reading_detail_page.dart
│   └── stats/stats_page.dart
└── widgets/                      # Tarjetas, controles y gráficos reutilizables
```

Flujo de datos:

```
Sensores físicos ─► SensorService / LocationService ─► Pantallas (tiempo real)
                                                        │  botón "Guardar" / monitoreo
                                                        ▼
                                              ReadingsRepository ─► Supabase (sensor_readings)
                                                        ▲
                         Historial / Estadísticas ──────┘ (consultas)
```

## Orden y dependencias

```
00 Configuración ─┬─► 01 Pantalla principal
                  ├─► 02 Monitoreo de sensores ─► 03 Registro en Supabase ─┬─► 04 Historial
                  │                                                       └─► 05 Estadísticas
                  └────────────────────────────────────────────────────────────► 06 Entregables
```

- **00** bloquea todo lo demás (dependencias, modelo, Supabase).
- **01** y **02** pueden hacerse en paralelo.
- **04** y **05** pueden hacerse en paralelo una vez exista **03** (y datos de prueba en la tabla).
- **06** se va construyendo durante todo el proyecto (capturas, README) y se cierra al final.

## Reparto sugerido para el grupo

| Bloque | Módulos | Responsable |
|--------|---------|-------------|
| A | 00 + 01 (configuración, navegación, splash, estado) | _por asignar_ |
| B | 02 (sensores y GPS) | _por asignar_ |
| C | 03 + 04 (repositorio Supabase, historial, detalle) | _por asignar_ |
| D | 05 + 06 (estadísticas, gráfico, informe y evidencias) | _por asignar_ |

Recomendación de flujo Git: una rama por módulo (`feat/modulo-1-inicio`, `feat/modulo-2-sensores`, …)
y Pull Request hacia `main` con revisión de al menos otro integrante.

## Definición de "terminado" (aplica a todos los módulos)

- [ ] Cumple todos los requisitos del documento listados en el archivo del módulo.
- [ ] `flutter analyze` sin errores ni warnings.
- [ ] Probado en un **dispositivo físico** (no solo emulador).
- [ ] Maneja errores: sensor no disponible, sin permisos, sin conexión a Supabase.
- [ ] Código comentado (doc comments `///` en clases y métodos públicos).
- [ ] Capturas de evidencia guardadas en `doc/evidencias/` (ver módulo 6).

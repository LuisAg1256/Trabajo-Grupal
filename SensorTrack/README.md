# SensorTrack

Aplicación Flutter para monitorear acelerómetro, giroscopio, magnetómetro y GPS,
guardar lecturas en Supabase y consultar su historial y estadísticas.

## Requisitos

- Flutter con Dart SDK `3.13.7` o posterior, conforme a `pubspec.yaml`.
- Proyecto Supabase y dispositivo Android o iOS para validar sensores y GPS.
- Acceso a Internet para Supabase y las teselas de OpenStreetMap.

## Configuración local

1. Copia `env.example.json` como `env.json` y completa la URL del proyecto y la
   clave pública de Supabase:

   ```powershell
   Copy-Item env.example.json env.json
   ```

2. Ejecuta el contenido de [`../supabase/schema.sql`](../supabase/schema.sql)
   desde el SQL Editor del proyecto Supabase. El script crea la tabla,
   permisos/políticas y la función RPC de estadísticas.
3. Desde esta carpeta, descarga las dependencias y ejecuta:

   ```powershell
   flutter pub get
   flutter run --dart-define-from-file=env.json
   ```

`env.json` está excluido de Git. No incluyas una clave `service_role` ni datos
reales de credenciales en commits.

## Arquitectura

```text
lib/
├── core/                 # Entorno, formato y errores del repositorio
├── models/               # SensorReading y modelos estadísticos
├── services/             # Sensores, ubicación, persistencia y fuente de estadísticas
├── features/             # Splash, inicio, sensores, ubicación, historial y estadísticas
└── widgets/              # Tarjetas, controles de guardado y gráficos reutilizables
```

La pantalla de estadísticas depende del contrato `SensorStatsSource`. Su
adaptador Supabase está separado de la UI, por lo que puede sustituirse en
pruebas sin cambiar la navegación ni los módulos de sensores e historial.

## Estado de módulos

| Módulo | Estado del código | Pendiente de integración/verificación |
|---|---|---|
| 00 Configuración | Configuración, modelo, permisos y esquema presentes | Confirmar credenciales locales y ejecutar el SQL en Supabase |
| 01 Inicio | Splash, navegación y estado del sistema | Validación en dispositivo |
| 02 Sensores | Streams de movimiento, ubicación y mapa | Validación en dispositivo y resolución local de dependencias |
| 03 Registro | Inserción y monitoreo por lotes | Verificar persistencia, consentimiento y reintentos |
| 04 Historial | Filtro, paginación y detalle | Comparar resultados con Supabase |
| 05 Estadísticas | Resumen, máximos/mínimos, última ubicación y series | Ejecutar el SQL y validar cifras contra la base |
| 06 Entregables | Informe, guion y lista de evidencias | Añadir capturas/video reales, integrantes y resultados de pruebas |

## Evidencias y documentación

- [`../doc/informe-tecnico.md`](../doc/informe-tecnico.md)
- [`../doc/guion-demostracion.md`](../doc/guion-demostracion.md)
- [`../doc/evidencias/README.md`](../doc/evidencias/README.md)
- [Plan de módulos](../doc/plan/README.md)

Las evidencias deben capturarse en un dispositivo real y no se simulan dentro
del repositorio.

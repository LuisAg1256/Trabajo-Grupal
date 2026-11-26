# 06 · Entregables finales

> Sección 12 del documento. Se prepara durante todo el proyecto y se cierra al final.

## Checklist de entregables

| # | Entregable (documento) | Cómo se cumple | Ubicación en el repo | Módulos |
|---|------------------------|----------------|----------------------|---------|
| 1 | Código fuente completo en GitHub bien documentado | README + doc comments `///` + `flutter analyze` limpio | `SensorTrack/`, `README.md` | Todos |
| 2 | Evidencias de la app en un dispositivo físico | Capturas/video con el modelo del teléfono visible | `doc/evidencias/dispositivo/` | 1–5 |
| 3 | Evidencia de la captura de los sensores | Video moviendo/girando el teléfono + captura de GPS | `doc/evidencias/sensores/` | 2 |
| 4 | Evidencia de los registros en Supabase | Capturas del *Table Editor* y de consultas SQL | `doc/evidencias/supabase/` | 3, 4, 5 |
| 5 | Script SQL de creación de la tabla | Tabla + índices + RLS + `sensor_stats()` | `supabase/schema.sql` | 0, 5 |
| 6 | Informe técnico breve | Arquitectura y funcionamiento | `doc/informe-tecnico.md` (o PDF) | Todos |
| 7 | Demostración práctica al docente | Guion de demo (abajo) | — | Todos |

## Tareas

### 6.1 Documentación del código y README
- [x] Documentar descripción, arquitectura, configuración de Supabase y ejecución en
  `SensorTrack/README.md` y el README raíz.
- [x] Crear informe técnico y guion de demostración.
- [ ] Completar los nombres de integrantes, capturas y versión exacta de Flutter usada en la entrega.
- [ ] Doc comments `///` en modelos, servicios y pantallas.
- [ ] Verificar que `env.json` y cualquier clave **no** estén en el historial de Git.

### 6.2 Evidencias (`doc/evidencias/`)
Ir guardándolas al terminar cada módulo (cada archivo de módulo lista las suyas):
- [ ] `dispositivo/`: splash, inicio, cada pantalla en el teléfono físico.
- [ ] `sensores/`: video del acelerómetro/giroscopio cambiando, captura del GPS.
- [ ] `supabase/`: tabla con filas, políticas RLS, consultas de verificación de estadísticas.
- [ ] Nombrar los archivos de forma descriptiva (`03-guardar-medicion-ok.png`).
- [x] Documentar la lista de capturas pendientes en `doc/evidencias/README.md`.

### 6.3 Informe técnico breve (2–4 páginas)
Estructura sugerida:
1. **Introducción y objetivo**.
2. **Arquitectura**: diagrama de capas (UI → servicios → Supabase), estructura de carpetas,
   paquetes usados y por qué.
3. **Sensores implementados**: acelerómetro, giroscopio, GPS (y magnetómetro si se añade);
   unidades, frecuencia de muestreo y cómo se detecta la disponibilidad.
4. **Base de datos**: tabla `sensor_readings`, índices, políticas RLS, función `sensor_stats`.
5. **Funcionamiento por módulo**: breve descripción + captura de cada pantalla.
6. **Consideraciones técnicas**: permisos, privacidad de la ubicación, control de frecuencia,
   manejo de errores (sección 11 del documento).
7. **Pruebas realizadas** y **conclusiones / mejoras futuras** (autenticación, modo offline, etc.).

### 6.4 Guion de la demostración (≈5 min)
1. Abrir la app → splash → Inicio: estado **Conectado** y sensores disponibles.
2. **Sensores**: mover y girar el teléfono mostrando los valores en vivo.
3. Pulsar **Guardar medición**; iniciar el monitoreo a 5 s unos segundos y detenerlo.
4. **Ubicación**: obtener coordenadas, aceptar consentimiento y **Guardar ubicación**.
5. Mostrar en el panel de Supabase que las filas nuevas existen.
6. **Historial**: ver las nuevas filas arriba, filtrar y abrir un detalle.
7. **Estadísticas**: totales, máx/mín, última ubicación y gráfico actualizado.
8. Activar modo avión e intentar guardar → error controlado.

### 6.5 Revisión final
- [ ] `flutter analyze` y `flutter test` en verde.
- [ ] Build de release instalable: `flutter build apk --release --dart-define-from-file=env.json`.
- [ ] Probar el APK de release en un teléfono (confirma el permiso `INTERNET`).
- [ ] Todos los checklists de los módulos 00–05 marcados.

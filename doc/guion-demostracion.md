# Guion de demostración — SensorTrack

**Duración objetivo:** 5 minutos.  
**Antes de iniciar:** teléfono con permisos disponibles, conexión a Internet,
credenciales configuradas y proyecto Supabase con el esquema aplicado.

| Tiempo | Acción | Resultado que se debe mostrar |
|---|---|---|
| 0:00–0:30 | Abrir la app y esperar el Splash | Inicio muestra estado de Supabase y sensores detectados |
| 0:30–1:15 | Abrir Sensores; mover y girar el teléfono | Cambian X/Y/Z del acelerómetro y giroscopio; mostrar magnetómetro si está disponible |
| 1:15–1:45 | Guardar una medición y ejecutar monitoreo con intervalo de 5 s; detenerlo | Mensaje de éxito y contador, sin ráfaga de inserciones |
| 1:45–2:30 | Abrir Ubicación; aceptar el aviso, obtener posición y guardar | Coordenadas y precisión; consentimiento de almacenamiento antes de insertar |
| 2:30–3:00 | Abrir Supabase Table Editor | Filas recientes de acelerómetro, giroscopio/GPS y sus fechas |
| 3:00–3:40 | Abrir Historial, cambiar filtro y abrir un detalle | Registros recientes, valores, fecha e información de GPS cuando corresponda |
| 3:40–4:35 | Abrir Estadísticas y cambiar entre acelerómetro, giroscopio y GPS | Total, conteos, máximos/mínimos, última ubicación y gráfico con tooltip |
| 4:35–5:00 | Desactivar conexión o activar modo avión e intentar guardar | Mensaje de error legible; la app permanece abierta |

No presentar como verificados los pasos que dependan de un backend, dispositivo o
permiso que no esté disponible durante la demostración.

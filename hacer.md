Analice los valores del acelerómetro.
Detecte cambios bruscos en la aceleración mediante un umbral definido y justificado.
Genere una alerta visual cuando se supere el umbral.
Registre el evento en Supabase.
Muestre un historial de eventos detectados.

Un nuevo esquema para supabase
Evento

CREATE TABLE IF NOT EXISTS event (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_type TEXT NOT NULL
                CHECK (sensor_type IN ('accelerometer')),
    x           DOUBLE PRECISION,
    y           DOUBLE PRECISION,
    z           DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

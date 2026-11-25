-- ============================================================================
-- SensorTrack — Esquema de base de datos en Supabase (PostgreSQL)
-- Módulo 00: Tabla sensor_readings, índices y políticas RLS
-- ============================================================================

-- 1. Tabla principal exigida por el taller (Sección 7)
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

-- 2. Índices para optimizar consultas de Historial (Módulo 4) y Estadísticas (Módulo 5)
CREATE INDEX IF NOT EXISTS idx_sensor_readings_recorded_at ON sensor_readings (recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_sensor_readings_type        ON sensor_readings (sensor_type);

-- 3. Seguridad a nivel de fila - RLS (Sección 11)
ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;

-- Políticas para clave pública (rol anon): lectura e inserción permitidas;
-- UPDATE y DELETE quedan bloqueados por defecto al no tener política.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sensor_readings' AND policyname = 'anon puede leer'
    ) THEN
        CREATE POLICY "anon puede leer"
            ON sensor_readings FOR SELECT TO anon USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'sensor_readings' AND policyname = 'anon puede insertar'
    ) THEN
        CREATE POLICY "anon puede insertar"
            ON sensor_readings FOR INSERT TO anon WITH CHECK (true);
    END IF;
END $$;

-- Nota para el compañero del Módulo 5 (Estadísticas):
-- Añadir aquí abajo la función RPC sensor_stats() descrita en doc/plan/05-modulo-estadisticas.md

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

-- Permisos de tabla para la clave pública (rol anon). Sin ellos la API responde
-- "42501 permission denied for table sensor_readings" aunque existan las políticas.
-- No se concede UPDATE ni DELETE.
GRANT SELECT, INSERT ON public.sensor_readings TO anon;

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

-- 4. Resumen para la pantalla de Estadísticas (Módulo 5).
CREATE OR REPLACE FUNCTION public.sensor_stats()
RETURNS JSON
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
    SELECT json_build_object(
        'total',
        (SELECT COUNT(*) FROM public.sensor_readings),
        'by_sensor',
        (
            SELECT COALESCE(json_object_agg(sensor_type, reading_count), '{}'::json)
            FROM (
                SELECT sensor_type, COUNT(*) AS reading_count
                FROM public.sensor_readings
                GROUP BY sensor_type
            ) AS sensor_counts
        ),
        'accelerometer',
        (
            SELECT json_build_object(
                'min_x', MIN(x),
                'max_x', MAX(x),
                'min_y', MIN(y),
                'max_y', MAX(y),
                'min_z', MIN(z),
                'max_z', MAX(z)
            )
            FROM public.sensor_readings
            WHERE sensor_type = 'accelerometer'
        ),
        'last_location',
        (
            SELECT json_build_object(
                'latitude', latitude,
                'longitude', longitude,
                'accuracy', accuracy,
                'recorded_at', recorded_at
            )
            FROM public.sensor_readings
            WHERE sensor_type = 'gps'
              AND latitude IS NOT NULL
              AND longitude IS NOT NULL
            ORDER BY recorded_at DESC
            LIMIT 1
        )
    );
$$;

GRANT EXECUTE ON FUNCTION public.sensor_stats() TO anon;

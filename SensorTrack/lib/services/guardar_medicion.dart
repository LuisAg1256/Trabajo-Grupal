// Código proporcionado por el docente — Sección 9 del taller
// "Ejemplo práctico: guardar información en Supabase".
// Se integra con el botón "Guardar medición" de la pantalla de Sensores
// (lib/widgets/guardar_medicion_button.dart), que maneja los errores de
// conexión o permisos.

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> guardarMedicion(
  double x,
  double y,
  double z,
) async {
  final supabase = Supabase.instance.client;

  await supabase.from('sensor_readings').insert({
    'sensor_type': 'accelerometer',
    'x': x,
    'y': y,
    'z': z,
  });
}

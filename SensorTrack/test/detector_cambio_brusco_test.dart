import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_track/models/event.dart';
import 'package:sensor_track/services/detector_cambio_brusco.dart';

void main() {
  test(
    'DetectorCambioBrusco: ignora ruido, detecta golpe y respeta la espera',
    () {
      final d = DetectorCambioBrusco();
      final t0 = DateTime(2026, 11, 27);

      expect(d.analizar(0, 0, 9.8, t0), isNull); // primera muestra
      expect(d.analizar(0.3, 0.2, 9.7, t0), isNull); // ruido en reposo
      expect(d.analizar(3, 2, 12, t0), isNull); // movimiento normal (~4.5)

      final delta = d.analizar(
        15,
        2,
        12,
        t0.add(const Duration(milliseconds: 66)),
      );
      expect(delta, closeTo(12, 0.001)); // justo en el umbral

      // Otra sacudida dentro de la espera de 2 s no genera evento.
      expect(d.analizar(0, 0, 9.8, t0.add(const Duration(seconds: 1))), isNull);
      // Pasada la espera sí.
      expect(
        d.analizar(0, 0, -9.8, t0.add(const Duration(seconds: 3))),
        isNotNull,
      );
    },
  );

  test('Event.fromMap acepta enteros de Supabase', () {
    final e = Event.fromMap({
      'id': 'a',
      'sensor_type': 'accelerometer',
      'x': 0,
      'y': 1.5,
      'z': null,
      'recorded_at': '2026-11-27T10:00:00Z',
    });
    expect(e.x, 0.0);
    expect(e.z, isNull);
  });
}

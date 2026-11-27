import 'dart:math' as math;

/// Detecta cambios bruscos de aceleración comparando cada muestra del
/// acelerómetro con la anterior: Δa = |a(t) − a(t−1)| (vector, m/s²).
///
/// Umbral = 12 m/s² (≈ 1.2 g) entre muestras consecutivas (~66 ms, `uiInterval`):
/// - En reposo la diferencia entre muestras es ruido (< 0.5 m/s²).
/// - Caminar o mover el teléfono en la mano produce Δa de ~2–6 m/s².
/// - Una sacudida fuerte, un golpe o una caída superan 1.2 g, y al comparar
///   el vector completo también se detecta el inicio de una caída libre
///   (la gravedad de 9.8 m/s² "desaparece" de golpe).
/// Tras un evento se ignoran los siguientes [espera] para que una misma
/// sacudida no genere decenas de registros en Supabase.
class DetectorCambioBrusco {
  static const double umbral = 12.0;
  static const Duration espera = Duration(seconds: 2);

  double? _x, _y, _z;
  DateTime? _ultimoEvento;

  /// Devuelve Δa si la muestra supera el [umbral] (fuera del tiempo de
  /// [espera]); en otro caso `null`.
  double? analizar(double x, double y, double z, DateTime ahora) {
    final px = _x, py = _y, pz = _z;
    _x = x;
    _y = y;
    _z = z;
    if (px == null || py == null || pz == null) return null;

    final dx = x - px, dy = y - py, dz = z - pz;
    final delta = math.sqrt(dx * dx + dy * dy + dz * dz);
    if (delta < umbral) return null;
    if (_ultimoEvento != null && ahora.difference(_ultimoEvento!) < espera) {
      return null;
    }
    _ultimoEvento = ahora;
    return delta;
  }
}

/// Configuración de entorno leída en tiempo de compilación mediante
/// `--dart-define-from-file=env.json`.
class Env {
  const Env._();

  /// URL del proyecto de Supabase (`https://xxxx.supabase.co`).
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Clave pública (anon / publishable key) de Supabase.
  static const String supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  /// Indica si se proporcionaron credenciales reales (no vacías ni de plantilla).
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseKey.isNotEmpty &&
        !supabaseUrl.contains('tu-proyecto.supabase.co') &&
        !supabaseKey.contains('tu-publishable');
  }
}

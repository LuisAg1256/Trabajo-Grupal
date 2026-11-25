import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Excepción de dominio con mensajes claros en español para operaciones contra
/// Supabase (lista para usarse en los Módulos 1, 3, 4 y 5).
class RepositoryException implements Exception {
  /// Mensaje legible para mostrar al usuario en UI / SnackBar.
  final String message;

  /// Causa original opcional para depuración.
  final Object? cause;

  const RepositoryException(this.message, [this.cause]);

  /// Convierte errores comunes de red y Supabase en mensajes comprensibles.
  factory RepositoryException.fromError(Object error) {
    if (error is RepositoryException) return error;
    if (error is TimeoutException) {
      return RepositoryException(
        'Tiempo de espera agotado al conectar con Supabase.',
        error,
      );
    }
    if (error is PostgrestException) {
      if (error.code == '42501') {
        return RepositoryException(
          'Permiso denegado por políticas RLS en la base de datos.',
          error,
        );
      }
      return RepositoryException(
        'Error de base de datos (${error.code ?? 'Postgrest'}): ${error.message}',
        error,
      );
    }
    if (error is AuthException) {
      return RepositoryException(
        'Error de autenticación con Supabase: ${error.message}',
        error,
      );
    }
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('ClientException')) {
      return RepositoryException(
        'Sin conexión a internet o servidor no disponible.',
        error,
      );
    }
    return RepositoryException('Error inesperado: $text', error);
  }

  @override
  String toString() => message;
}

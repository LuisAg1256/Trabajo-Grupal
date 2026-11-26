import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';
import '../core/repository_exception.dart';
import '../models/sensor_reading.dart';

/// Repositorio central para acceder a la tabla `sensor_readings` en Supabase.
///
/// - **Módulo 1:** Implementa [checkConnection] para verificar el estado en Inicio.
/// - **Módulo 3:** Completar inserción individual y por lotes ([insert], [insertMany]).
/// - **Módulo 4:** Completar consultas paginadas y detalle ([fetchPage], [fetchById]).
/// - **Módulo 5:** Añadir consultas de estadísticas (`fetchStats`, `fetchSeries`).
class ReadingsRepository {
  ReadingsRepository();

  /// Nombre de la tabla en Supabase.
  static const String table = 'sensor_readings';

  /// Bandera actualizada en `main.dart` tras inicializar `Supabase.initialize`.
  static bool isSupabaseInitialized = false;

  /// Tiempo máximo de espera para inserciones y consultas.
  static const Duration _timeout = Duration(seconds: 10);

  /// Avisa cada vez que se guardan mediciones nuevas, para que pantallas como
  /// el Historial se recarguen solas.
  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  /// Se emite un evento después de cada inserción correcta (Módulos 3 y 4).
  Stream<void> get changes => _changes.stream;

  /// Avisa al Historial de un guardado hecho fuera del repositorio, por
  /// ejemplo con la función `guardarMedicion` del docente.
  static void notificarCambios() => _changes.add(null);

  /// Último detalle de error de conexión (útil para mostrar diagnóstico en Inicio).
  String? lastConnectionError;

  /// Cliente de Supabase (solo debe accederse cuando [isSupabaseInitialized] es `true`).
  SupabaseClient get client {
    if (!isSupabaseInitialized) {
      throw const RepositoryException(
        'Supabase no está inicializado. Configura env.json y ejecuta con --dart-define-from-file=env.json.',
      );
    }
    return Supabase.instance.client;
  }

  /// Comprueba si Supabase responde consultando como máximo 1 fila con timeout de 5 s.
  Future<bool> checkConnection() async {
    if (!Env.isConfigured) {
      lastConnectionError = 'Credenciales pendientes en env.json (--dart-define-from-file=env.json)';
      return false;
    }
    if (!isSupabaseInitialized) {
      lastConnectionError = 'Cliente de Supabase no inicializado';
      return false;
    }

    try {
      await client
          .from(table)
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      lastConnectionError = null;
      return true;
    } catch (e) {
      lastConnectionError = RepositoryException.fromError(e).message;
      return false;
    }
  }

  // ===========================================================================
  // PUNTOS DE EXTENSIÓN PARA LOS COMPAÑEROS (MÓDULOS 3, 4 Y 5)
  // ===========================================================================

  /// [Módulo 3] Inserta una lectura individual en `sensor_readings`.
  Future<void> insert(SensorReading reading) async {
    await _run(() => client.from(table).insert(reading.toInsertMap()));
    _changes.add(null);
  }

  /// [Módulo 3] Inserta un lote de lecturas en `sensor_readings` en una sola
  /// petición (monitoreo automático).
  Future<void> insertMany(List<SensorReading> readings) async {
    if (readings.isEmpty) return;
    await _run(
      () => client
          .from(table)
          .insert(readings.map((r) => r.toInsertMap()).toList()),
    );
    _changes.add(null);
  }

  /// [Módulo 4] Obtiene una página de lecturas ordenadas por `recorded_at DESC`,
  /// entre las posiciones [from] y [to] (inclusive), opcionalmente filtradas por [type].
  Future<List<SensorReading>> fetchPage({
    int from = 0,
    int to = 19,
    SensorType? type,
  }) {
    return _run(() async {
      var query = client.from(table).select();
      if (type != null) query = query.eq('sensor_type', type.name);
      final rows = await query
          .order('recorded_at', ascending: false)
          .range(from, to);
      return rows.map(SensorReading.fromMap).toList();
    });
  }

  /// [Módulo 4] Consulta una lectura específica por su `id` (`null` si no existe).
  Future<SensorReading?> fetchById(String id) {
    return _run(() async {
      final row = await client.from(table).select().eq('id', id).maybeSingle();
      return row == null ? null : SensorReading.fromMap(row);
    });
  }

  /// Ejecuta [action] con tiempo límite y convierte cualquier error en
  /// [RepositoryException].
  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } catch (e) {
      throw RepositoryException.fromError(e);
    }
  }
}


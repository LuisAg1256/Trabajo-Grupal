import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env.dart';
import 'services/readings_repository.dart';

/// Punto de entrada principal de SensorTrack (Módulo 00).
/// Inicializa Supabase de forma segura antes de lanzar la interfaz.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.isConfigured) {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseKey,
      );
      ReadingsRepository.isSupabaseInitialized = true;
    } catch (e) {
      ReadingsRepository.isSupabaseInitialized = false;
      debugPrint('Aviso: No se pudo inicializar Supabase al arrancar: $e');
    }
  } else {
    ReadingsRepository.isSupabaseInitialized = false;
  }

  runApp(const SensorTrackApp());
}

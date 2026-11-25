import 'package:flutter/material.dart';

import 'features/splash/splash_page.dart';

/// Widget raíz de la aplicación SensorTrack (Módulo 1.1).
/// Define el tema Material 3 claro/oscuro y establece [SplashPage] como inicio.
class SensorTrackApp extends StatelessWidget {
  const SensorTrackApp({super.key});

  static const Color seedColor = Color.fromARGB(255, 1, 169, 184);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SensorTrack',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 1,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 1,
        ),
      ),
      home: const SplashPage(),
    );
  }
}

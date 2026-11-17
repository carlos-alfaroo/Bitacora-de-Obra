import 'package:flutter/material.dart';

import '../../dominio/entidades/preferencias.dart';

/// Tema Material 3 de la app, generado a partir de un naranja de seguridad
/// (el color de los chalecos y señalamientos de obra).
abstract final class TemaApp {
  static const semilla = Color(0xFFE2711D);

  static final ThemeData claro = _construir(Brightness.light);
  static final ThemeData oscuro = _construir(Brightness.dark);

  static ThemeData _construir(Brightness brillo) {
    final esquema =
        ColorScheme.fromSeed(seedColor: semilla, brightness: brillo);
    return ThemeData(
      colorScheme: esquema,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: esquema.surface,
        scrolledUnderElevation: 2,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: esquema.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: esquema.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: esquema.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerHighest.withValues(alpha: .35),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      chipTheme: const ChipThemeData(showCheckmark: false),
    );
  }
}

/// Traduce la preferencia del dominio al tipo de Flutter.
extension ModoTemaFlutter on ModoTema {
  ThemeMode get aThemeMode => switch (this) {
        ModoTema.sistema => ThemeMode.system,
        ModoTema.claro => ThemeMode.light,
        ModoTema.oscuro => ThemeMode.dark,
      };
}

import 'package:flutter/material.dart';

import '../../dominio/entidades/categoria_entrada.dart';

/// Apariencia de cada categoría. Vive en la presentación para que la
/// entidad del dominio no dependa de Flutter.
extension CategoriaVisual on CategoriaEntrada {
  IconData get icono => switch (this) {
        CategoriaEntrada.avance => Icons.trending_up_rounded,
        CategoriaEntrada.incidencia => Icons.report_problem_outlined,
        CategoriaEntrada.seguridad => Icons.health_and_safety_outlined,
        CategoriaEntrada.materiales => Icons.inventory_2_outlined,
        CategoriaEntrada.inspeccion => Icons.fact_check_outlined,
      };

  Color get _colorBase => switch (this) {
        CategoriaEntrada.avance => const Color(0xFF2E7D32),
        CategoriaEntrada.incidencia => const Color(0xFFC62828),
        CategoriaEntrada.seguridad => const Color(0xFFE65100),
        CategoriaEntrada.materiales => const Color(0xFF1565C0),
        CategoriaEntrada.inspeccion => const Color(0xFF6A1B9A),
      };

  /// Color ajustado al tema: más claro en modo oscuro para mantener contraste.
  Color colorEn(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Color.lerp(_colorBase, Colors.white, .4)!
          : _colorBase;
}

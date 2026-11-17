import 'package:flutter/material.dart';

import '../../dominio/entidades/categoria_entrada.dart';
import '../tema/categoria_visual.dart';

/// Etiqueta de color con el icono y el nombre de la categoría.
class ChipCategoria extends StatelessWidget {
  const ChipCategoria({super.key, required this.categoria, this.compacto = false});

  final CategoriaEntrada categoria;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final color = categoria.colorEn(context);
    final estilo = (compacto
            ? Theme.of(context).textTheme.labelSmall
            : Theme.of(context).textTheme.labelLarge)
        ?.copyWith(color: color, fontWeight: FontWeight.w700);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compacto ? 8 : 12, vertical: compacto ? 3 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(categoria.icono, size: compacto ? 13 : 16, color: color),
          SizedBox(width: compacto ? 4 : 6),
          Text(categoria.etiqueta, style: estilo),
        ],
      ),
    );
  }
}

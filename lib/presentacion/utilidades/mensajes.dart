import 'package:flutter/material.dart';

/// Muestra un aviso breve en la parte inferior (SnackBar).
void mostrarMensaje(
  BuildContext context,
  String texto, {
  IconData icono = Icons.check_circle_outline,
}) {
  final esquema = Theme.of(context).colorScheme;
  _mostrar(context, texto, icono, esquema.inverseSurface, esquema.onInverseSurface);
}

/// Muestra un error de forma visible (SnackBar con color de error).
void mostrarError(BuildContext context, String texto) {
  final esquema = Theme.of(context).colorScheme;
  _mostrar(context, texto, Icons.error_outline, esquema.error, esquema.onError);
}

void _mostrar(
    BuildContext context, String texto, IconData icono, Color fondo, Color frente) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: fondo,
      content: Row(children: [
        Icon(icono, color: frente),
        const SizedBox(width: 12),
        Expanded(child: Text(texto, style: TextStyle(color: frente))),
      ]),
    ));
}

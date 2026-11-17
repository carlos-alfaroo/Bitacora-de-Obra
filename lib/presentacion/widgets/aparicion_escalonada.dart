import 'package:flutter/material.dart';

/// Animación de entrada: el hijo aparece desvaneciéndose y subiendo un poco.
/// Con [indice] cada elemento de una lista tarda un poco más que el anterior.
class AparicionEscalonada extends StatelessWidget {
  const AparicionEscalonada({super.key, required this.indice, required this.child});

  final int indice;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + 45 * indice.clamp(0, 8)),
      curve: Curves.easeOutCubic,
      builder: (context, valor, hijo) => Opacity(
        opacity: valor,
        child: Transform.translate(offset: Offset(0, 18 * (1 - valor)), child: hijo),
      ),
      child: child,
    );
  }
}

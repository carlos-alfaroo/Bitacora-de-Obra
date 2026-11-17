import 'package:flutter/material.dart';

/// Botón de micrófono para dictar. Mientras escucha, un anillo animado crece
/// según el volumen que capta el micrófono ([nivel], de 0 a 1).
class PanelDictado extends StatelessWidget {
  const PanelDictado({
    super.key,
    required this.escuchando,
    required this.nivel,
    required this.idioma,
    required this.alPresionar,
  });

  final bool escuchando;
  final double nivel;
  final String idioma;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final colorActivo = escuchando ? esquema.error : esquema.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: escuchando
            ? esquema.errorContainer.withValues(alpha: .55)
            : esquema.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Anillo que "respira" con el volumen de la voz.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: escuchando ? 50 + 18 * nivel : 50,
                  height: escuchando ? 50 + 18 * nivel : 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorActivo.withValues(alpha: escuchando ? .25 : 0),
                  ),
                ),
                Tooltip(
                  message: escuchando ? 'Detener dictado' : 'Dictar con el micrófono',
                  child: Material(
                    color: colorActivo,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: alPresionar,
                      child: SizedBox.square(
                        dimension: 50,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (hijo, animacion) =>
                              ScaleTransition(scale: animacion, child: hijo),
                          child: Icon(
                            escuchando ? Icons.stop_rounded : Icons.mic_rounded,
                            key: ValueKey(escuchando),
                            color: escuchando ? esquema.onError : esquema.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey(escuchando),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    escuchando ? 'Escuchando…' : 'Dictar descripción',
                    style: tema.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    escuchando
                        ? 'Habla con claridad. Toca el botón para terminar.'
                        : 'Escribe con tu voz · $idioma',
                    style: tema.textTheme.bodySmall
                        ?.copyWith(color: esquema.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

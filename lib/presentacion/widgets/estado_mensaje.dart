import 'package:flutter/material.dart';

/// Pantalla de estado (vacío, error, sin resultados) con acción opcional.
///
/// Es desplazable para que funcione dentro de un RefreshIndicator.
class EstadoMensaje extends StatelessWidget {
  const EstadoMensaje({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.textoAccion,
    this.alAccionar,
  });

  final IconData icono;
  final String titulo;
  final String? mensaje;
  final String? textoAccion;
  final VoidCallback? alAccionar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tema.colorScheme.primaryContainer.withValues(alpha: .6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icono,
                        size: 48, color: tema.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 20),
                  Text(titulo,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (mensaje != null) ...[
                    const SizedBox(height: 8),
                    Text(mensaje!,
                        textAlign: TextAlign.center,
                        style: tema.textTheme.bodyMedium?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant)),
                  ],
                  if (textoAccion != null && alAccionar != null) ...[
                    const SizedBox(height: 20),
                    FilledButton.tonal(
                        onPressed: alAccionar, child: Text(textoAccion!)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

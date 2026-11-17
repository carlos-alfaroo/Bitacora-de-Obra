import 'dart:io';

import 'package:flutter/material.dart';

import '../../dominio/servicios/servicio_imagenes.dart';

/// Vista previa de la foto con botones para tomarla con la cámara, elegirla
/// de la galería o quitarla. La lógica la resuelve la pantalla que lo usa.
class SelectorImagen extends StatelessWidget {
  const SelectorImagen({
    super.key,
    required this.rutaImagen,
    required this.alElegir,
    required this.alQuitar,
  });

  final String? rutaImagen;
  final ValueChanged<OrigenImagen> alElegir;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    final ruta = rutaImagen;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (hijo, animacion) => FadeTransition(
        opacity: animacion,
        child: ScaleTransition(
          scale: Tween(begin: .96, end: 1.0).animate(animacion),
          child: hijo,
        ),
      ),
      child: ruta == null
          ? _SinImagen(key: const ValueKey('sin-imagen'), alElegir: alElegir)
          : _ConImagen(
              key: ValueKey(ruta),
              ruta: ruta,
              alElegir: alElegir,
              alQuitar: alQuitar,
            ),
    );
  }
}

class _SinImagen extends StatelessWidget {
  const _SinImagen({super.key, required this.alElegir});

  final ValueChanged<OrigenImagen> alElegir;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: esquema.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: esquema.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 40, color: esquema.primary),
          const SizedBox(height: 8),
          Text('Agrega una foto de evidencia',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => alElegir(OrigenImagen.camara),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Cámara'),
              ),
              OutlinedButton.icon(
                onPressed: () => alElegir(OrigenImagen.galeria),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConImagen extends StatelessWidget {
  const _ConImagen({
    super.key,
    required this.ruta,
    required this.alElegir,
    required this.alQuitar,
  });

  final String ruta;
  final ValueChanged<OrigenImagen> alElegir;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(ruta),
              fit: BoxFit.cover,
              cacheWidth: 1080,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Colors.black12,
                child: Center(child: Icon(Icons.broken_image_outlined, size: 48)),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  _BotonSobreFoto(
                    icono: Icons.photo_camera_outlined,
                    ayuda: 'Tomar otra foto',
                    alTocar: () => alElegir(OrigenImagen.camara),
                  ),
                  _BotonSobreFoto(
                    icono: Icons.photo_library_outlined,
                    ayuda: 'Elegir de la galería',
                    alTocar: () => alElegir(OrigenImagen.galeria),
                  ),
                  _BotonSobreFoto(
                    icono: Icons.close,
                    ayuda: 'Quitar foto',
                    alTocar: alQuitar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonSobreFoto extends StatelessWidget {
  const _BotonSobreFoto({
    required this.icono,
    required this.ayuda,
    required this.alTocar,
  });

  final IconData icono;
  final String ayuda;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: IconButton(
          tooltip: ayuda,
          onPressed: alTocar,
          icon: Icon(icono),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
          ),
        ),
      );
}

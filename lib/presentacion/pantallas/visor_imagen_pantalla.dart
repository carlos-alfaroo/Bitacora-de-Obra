import 'dart:io';

import 'package:flutter/material.dart';

import '../navegacion/rutas.dart';

/// Foto a pantalla completa con zoom (pellizcar) y animación Hero desde el
/// detalle.
class VisorImagenPantalla extends StatelessWidget {
  const VisorImagenPantalla({super.key, required this.argumentos});

  final ArgumentosVisorImagen argumentos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black38,
        foregroundColor: Colors.white,
        title: Text(argumentos.titulo, style: const TextStyle(color: Colors.white)),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Hero(
            tag: argumentos.etiquetaHero,
            child: Image.file(
              File(argumentos.rutaImagen),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

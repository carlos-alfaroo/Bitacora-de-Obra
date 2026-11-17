import 'dart:io';

import 'package:flutter/material.dart';

import '../../dominio/entidades/categoria_entrada.dart';
import '../tema/categoria_visual.dart';

/// Muestra la foto guardada en [ruta]. Si no hay foto, o el archivo ya no
/// existe, dibuja un marcador con el icono de la [categoria].
class ImagenEntrada extends StatelessWidget {
  const ImagenEntrada({
    super.key,
    required this.ruta,
    required this.categoria,
    this.ajuste = BoxFit.cover,
    this.anchoCache,
    this.tamanoIcono = 32,
  });

  final String? ruta;
  final CategoriaEntrada categoria;
  final BoxFit ajuste;

  /// Decodifica la imagen a este ancho (en píxeles) para ahorrar memoria en
  /// las miniaturas de la lista.
  final int? anchoCache;
  final double tamanoIcono;

  @override
  Widget build(BuildContext context) {
    final rutaImagen = ruta;
    if (rutaImagen == null || rutaImagen.isEmpty) {
      return _Marcador(categoria: categoria, tamanoIcono: tamanoIcono);
    }
    return Image.file(
      File(rutaImagen),
      fit: ajuste,
      cacheWidth: anchoCache,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _Marcador(
        categoria: categoria,
        tamanoIcono: tamanoIcono,
        roto: true,
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador({
    required this.categoria,
    required this.tamanoIcono,
    this.roto = false,
  });

  final CategoriaEntrada categoria;
  final double tamanoIcono;
  final bool roto;

  @override
  Widget build(BuildContext context) {
    final color = categoria.colorEn(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: .28), color.withValues(alpha: .10)],
        ),
      ),
      child: Center(
        child: Icon(
          roto ? Icons.broken_image_outlined : categoria.icono,
          size: tamanoIcono,
          color: color,
          semanticLabel: roto ? 'Imagen no disponible' : categoria.etiqueta,
        ),
      ),
    );
  }
}

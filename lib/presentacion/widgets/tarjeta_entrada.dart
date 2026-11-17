import 'package:flutter/material.dart';

import '../../core/utilidades/formato.dart';
import '../../dominio/entidades/entrada.dart';
import 'chip_categoria.dart';
import 'imagen_entrada.dart';

/// Elemento de la lista principal: miniatura (con Hero), categoría, título,
/// extracto de la descripción, fecha e indicadores de foto y GPS.
class TarjetaEntrada extends StatelessWidget {
  const TarjetaEntrada({super.key, required this.entrada, required this.alTocar});

  final Entrada entrada;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final secundario = tema.colorScheme.onSurfaceVariant;
    return Card(
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Misma etiqueta Hero que la cabecera del detalle: Flutter anima
              // la imagen de esta posición a la de la pantalla siguiente.
              Hero(
                tag: entrada.etiquetaHero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 88,
                    child: ImagenEntrada(
                      ruta: entrada.rutaImagen,
                      categoria: entrada.categoria,
                      anchoCache: 270,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChipCategoria(categoria: entrada.categoria, compacto: true),
                    const SizedBox(height: 6),
                    Text(
                      entrada.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entrada.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.bodyMedium?.copyWith(color: secundario),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: secundario),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            Formato.fechaRelativa(entrada.fecha),
                            style: tema.textTheme.labelMedium
                                ?.copyWith(color: secundario),
                          ),
                        ),
                        if (entrada.tieneImagen)
                          Icon(Icons.photo_camera_outlined,
                              size: 16,
                              color: secundario,
                              semanticLabel: 'Con foto'),
                        if (entrada.tieneUbicacion) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.location_on,
                              size: 16,
                              color: tema.colorScheme.primary,
                              semanticLabel: 'Con ubicación GPS'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

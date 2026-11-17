import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/errores/excepciones.dart';
import '../../core/utilidades/formato.dart';
import '../../dominio/entidades/entrada.dart';
import '../inyeccion/dependencias.dart';
import '../navegacion/rutas.dart';
import '../tema/categoria_visual.dart';
import '../widgets/chip_categoria.dart';
import '../widgets/estado_mensaje.dart';
import '../widgets/imagen_entrada.dart';
import '../widgets/mapa_comun.dart';

/// Mapa interactivo con todas las entradas que tienen ubicación GPS.
/// Cada pin usa el color de su categoría; al tocarlo se ve un resumen.
class MapaEntradasPantalla extends StatefulWidget {
  const MapaEntradasPantalla({super.key, this.enfocar});

  /// Si se indica, el mapa se centra en esta entrada (botón «Ampliar»).
  final Entrada? enfocar;

  @override
  State<MapaEntradasPantalla> createState() => _MapaEntradasPantallaState();
}

class _MapaEntradasPantallaState extends State<MapaEntradasPantalla> {
  late Future<List<Entrada>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<Entrada>> _cargar() async {
    final todas = await context.dependencias.entradas.obtenerTodas();
    return todas.where((e) => e.tieneUbicacion).toList();
  }

  LatLng _punto(Entrada e) => LatLng(e.ubicacion!.latitud, e.ubicacion!.longitud);

  MapOptions _opciones(List<Entrada> entradas) {
    final foco = widget.enfocar;
    if (foco != null && foco.tieneUbicacion) {
      return MapOptions(
          initialCenter: _punto(foco),
          initialZoom: 17,
          interactionOptions: MapaComun.interaccion);
    }
    if (entradas.length == 1) {
      return MapOptions(
          initialCenter: _punto(entradas.first),
          initialZoom: 16,
          interactionOptions: MapaComun.interaccion);
    }
    // Encuadra todos los pines en pantalla.
    return MapOptions(
      initialCameraFit: CameraFit.coordinates(
        coordinates: entradas.map(_punto).toList(),
        padding: const EdgeInsets.all(64),
        maxZoom: 17,
      ),
      interactionOptions: MapaComun.interaccion,
    );
  }

  void _mostrarResumen(Entrada entrada) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (contextoHoja) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox.square(
                      dimension: 72,
                      child: ImagenEntrada(
                        ruta: entrada.rutaImagen,
                        categoria: entrada.categoria,
                        anchoCache: 220,
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
                        Text(entrada.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(contextoHoja)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(Formato.fechaRelativa(entrada.fecha)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(contextoHoja);
                  Navigator.pushNamed(context, Rutas.detalle, arguments: entrada);
                },
                icon: const Icon(Icons.article_outlined),
                label: const Text('Ver detalle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de entradas')),
      body: FutureBuilder<List<Entrada>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error;
            return EstadoMensaje(
              icono: Icons.error_outline,
              titulo: 'No se pudo cargar el mapa',
              mensaje: error is BitacoraException ? error.mensaje : '$error',
              textoAccion: 'Reintentar',
              alAccionar: () => setState(() {
                _futuro = _cargar();
              }),
            );
          }
          final entradas = snapshot.data;
          if (entradas == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (entradas.isEmpty) {
            return const EstadoMensaje(
              icono: Icons.location_off_outlined,
              titulo: 'Aún no hay entradas con ubicación',
              mensaje: 'Las entradas guardan la posición GPS al crearse.',
            );
          }
          return FlutterMap(
            options: _opciones(entradas),
            children: [
              MapaComun.capaTeselas(context),
              MarkerLayer(
                markers: [
                  for (final entrada in entradas)
                    Marker(
                      point: _punto(entrada),
                      width: 46,
                      height: 46,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _mostrarResumen(entrada),
                        child: PinMapa(
                          color: entrada.categoria.colorEn(context),
                          tamano: entrada.id == widget.enfocar?.id ? 46 : 38,
                        ),
                      ),
                    ),
                ],
              ),
              MapaComun.atribucion(),
            ],
          );
        },
      ),
    );
  }
}

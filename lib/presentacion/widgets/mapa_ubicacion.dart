import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../dominio/entidades/ubicacion.dart';
import 'mapa_comun.dart';

/// Mapa interactivo (arrastrar y hacer zoom) centrado en una [ubicacion],
/// con un círculo que representa la precisión del GPS.
class MapaUbicacion extends StatelessWidget {
  const MapaUbicacion({super.key, required this.ubicacion, this.altura = 220});

  final Ubicacion ubicacion;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final punto = LatLng(ubicacion.latitud, ubicacion.longitud);
    final precision = ubicacion.precisionMetros;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: altura,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: punto,
            initialZoom: 17,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: MapaComun.interaccion,
          ),
          children: [
            MapaComun.capaTeselas(context),
            if (precision != null && precision > 0)
              CircleLayer(circles: [
                CircleMarker(
                  point: punto,
                  radius: precision,
                  useRadiusInMeter: true,
                  color: esquema.primary.withValues(alpha: .15),
                  borderColor: esquema.primary.withValues(alpha: .6),
                  borderStrokeWidth: 1.5,
                ),
              ]),
            MarkerLayer(markers: [
              Marker(
                point: punto,
                width: 48,
                height: 48,
                // topCenter: la punta del pin queda justo sobre la coordenada.
                alignment: Alignment.topCenter,
                child: PinMapa(color: esquema.primary, tamano: 48),
              ),
            ]),
            MapaComun.atribucion(),
          ],
        ),
      ),
    );
  }
}

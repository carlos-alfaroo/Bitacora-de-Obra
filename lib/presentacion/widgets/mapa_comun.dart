import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Piezas compartidas por los mapas de la app (flutter_map + OpenStreetMap).
///
/// Se eligió OpenStreetMap porque no requiere clave de API; para Google Maps
/// se ofrece además un botón que abre la app oficial con las coordenadas.
abstract final class MapaComun {
  /// Identifica la app ante los servidores de OSM (política de uso).
  static const _paquete = 'com.bitacora.bitacora_obra';

  static TileLayer capaTeselas(BuildContext context) => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: _paquete,
        maxNativeZoom: 19,
        // En modo oscuro se invierten los colores del mapa.
        tileBuilder: Theme.of(context).brightness == Brightness.dark
            ? darkModeTileBuilder
            : null,
      );

  static Widget atribucion() => const SimpleAttributionWidget(
        source: Text('OpenStreetMap contributors'),
      );

  /// Interacción completa salvo rotación (evita giros accidentales).
  static const interaccion = InteractionOptions(
    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
  );
}

/// Marcador en forma de pin con sombra para que destaque sobre el mapa.
class PinMapa extends StatelessWidget {
  const PinMapa({super.key, required this.color, this.tamano = 44});

  final Color color;
  final double tamano;

  @override
  Widget build(BuildContext context) => Icon(
        Icons.location_on,
        size: tamano,
        color: color,
        shadows: const [Shadow(blurRadius: 6, color: Colors.black45)],
      );
}

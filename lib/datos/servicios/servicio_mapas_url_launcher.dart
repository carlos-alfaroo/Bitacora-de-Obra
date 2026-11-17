import 'package:url_launcher/url_launcher.dart';

import '../../core/errores/excepciones.dart';
import '../../dominio/entidades/ubicacion.dart';
import '../../dominio/servicios/servicio_mapas_externos.dart';

/// Abre Google Maps con url_launcher usando la URL universal de Maps.
///
/// Si la app de Google Maps está instalada, Android la abre directamente;
/// si no, se abre en el navegador.
class ServicioMapasUrlLauncher implements ServicioMapasExternos {
  const ServicioMapasUrlLauncher();

  @override
  Future<void> abrirEnGoogleMaps(Ubicacion ubicacion) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${ubicacion.latitud},${ubicacion.longitud}',
    });
    try {
      final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abierto) {
        throw const MapaExternoException(
            'No hay ninguna aplicación para abrir el mapa.');
      }
    } on MapaExternoException {
      rethrow;
    } catch (e) {
      throw MapaExternoException('No se pudo abrir Google Maps.', causa: e);
    }
  }
}

import '../entidades/ubicacion.dart';

/// Abre una aplicación de mapas externa con las coordenadas guardadas.
abstract interface class ServicioMapasExternos {
  /// Lanza `MapaExternoException` si no hay aplicación que pueda abrirlo.
  Future<void> abrirEnGoogleMaps(Ubicacion ubicacion);
}

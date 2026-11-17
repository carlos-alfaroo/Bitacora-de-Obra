/// Excepciones propias de la aplicación.
///
/// Cada capa de datos traduce los errores técnicos de los paquetes externos
/// (sqflite, geolocator, image_picker, speech_to_text, url_launcher) a una de
/// estas excepciones. Así la capa de presentación sólo conoce [BitacoraException]
/// y puede mostrar un [mensaje] entendible sin depender de ningún paquete.
library;

/// Clase base sellada: el compilador conoce todos los subtipos posibles,
/// lo que permite usar `switch` exhaustivos sobre ella.
sealed class BitacoraException implements Exception {
  const BitacoraException(this.mensaje, {this.causa});

  /// Texto pensado para mostrarse al usuario.
  final String mensaje;

  /// Error original (útil para depurar; nunca se muestra al usuario).
  final Object? causa;

  @override
  String toString() => '$runtimeType: $mensaje${causa == null ? '' : ' ($causa)'}';
}

/// Fallo al leer o escribir en la base de datos local (SQLite) o en
/// las preferencias (SharedPreferences).
final class AlmacenamientoException extends BitacoraException {
  const AlmacenamientoException(super.mensaje, {super.causa});
}

/// Motivos por los que no se pudo obtener la ubicación GPS.
enum MotivoFalloUbicacion {
  servicioDesactivado,
  permisoDenegado,
  permisoDenegadoPermanente,
  tiempoAgotado,
  desconocido;

  /// Indica si el usuario puede resolverlo desde los ajustes del sistema.
  bool get seResuelveEnAjustes =>
      this == servicioDesactivado || this == permisoDenegadoPermanente;
}

/// Fallo al obtener la posición GPS.
final class UbicacionException extends BitacoraException {
  const UbicacionException(this.motivo, super.mensaje, {super.causa});

  final MotivoFalloUbicacion motivo;
}

/// Fallo al usar la cámara o la galería, o al guardar la imagen.
final class MultimediaException extends BitacoraException {
  const MultimediaException(super.mensaje, {super.causa});
}

/// Fallo del micrófono o del reconocimiento de voz.
final class DictadoException extends BitacoraException {
  const DictadoException(super.mensaje, {super.causa});
}

/// Fallo al abrir una aplicación externa (Google Maps).
final class MapaExternoException extends BitacoraException {
  const MapaExternoException(super.mensaje, {super.causa});
}

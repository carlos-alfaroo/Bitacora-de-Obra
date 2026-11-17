/// De dónde se obtiene la imagen de la entrada.
enum OrigenImagen { camara, galeria }

/// Gadget multimedia: cámara y galería del dispositivo.
///
/// Todas las operaciones lanzan `MultimediaException` si fallan.
abstract interface class ServicioImagenes {
  /// Abre la cámara o la galería y devuelve la ruta **temporal** de la
  /// imagen elegida, o `null` si el usuario canceló.
  Future<String?> seleccionar(OrigenImagen origen);

  /// Copia la imagen temporal al almacenamiento privado de la app para que
  /// no se pierda cuando el sistema limpie la caché. Devuelve la ruta final.
  Future<String> guardarPermanente(String rutaTemporal);

  /// Borra un archivo de imagen que ya no se usa.
  Future<void> eliminar(String ruta);
}

/// Nombres de las rutas de la app. Usar constantes evita errores de tipeo
/// en `Navigator.pushNamed`.
abstract final class Rutas {
  static const inicio = '/';
  static const detalle = '/entrada';
  static const nueva = '/entrada/nueva';
  static const editar = '/entrada/editar';
  static const imagen = '/entrada/imagen';
  static const mapa = '/mapa';
  static const ajustes = '/ajustes';
  static const acercaDe = '/acerca-de';
}

/// Lo que devuelven el formulario y el detalle al cerrarse
/// (`Navigator.pop(context, resultado)`), para que la lista sepa qué pasó.
enum ResultadoEntrada { creada, actualizada, eliminada }

/// Argumentos de la ruta [Rutas.imagen].
class ArgumentosVisorImagen {
  const ArgumentosVisorImagen({
    required this.rutaImagen,
    required this.etiquetaHero,
    required this.titulo,
  });

  final String rutaImagen;
  final String etiquetaHero;
  final String titulo;
}

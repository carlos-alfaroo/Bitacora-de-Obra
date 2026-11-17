import 'categoria_entrada.dart';
import 'ubicacion.dart';

/// Un registro de la bitácora: qué pasó, cuándo, dónde y con qué evidencia.
///
/// Es inmutable: para modificarla se crea una nueva instancia. Esto evita
/// que una pantalla altere por accidente los datos que muestra otra.
class Entrada {
  const Entrada({
    this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.fecha,
    this.rutaImagen,
    this.ubicacion,
  });

  /// Identificador asignado por SQLite. Es `null` mientras no se ha guardado.
  final int? id;
  final String titulo;
  final String descripcion;
  final CategoriaEntrada categoria;

  /// Momento en que se creó el registro.
  final DateTime fecha;

  /// Ruta del archivo de imagen dentro del almacenamiento de la app.
  final String? rutaImagen;

  /// Posición GPS capturada al guardar (puede faltar si el GPS falló).
  final Ubicacion? ubicacion;

  bool get tieneImagen => rutaImagen != null && rutaImagen!.isNotEmpty;
  bool get tieneUbicacion => ubicacion != null;

  /// Etiqueta única para la animación Hero entre la lista y el detalle.
  String get etiquetaHero => 'imagen-entrada-${id ?? identityHashCode(this)}';

  /// Devuelve una copia con el [id] que asignó la base de datos.
  Entrada copiarConId(int nuevoId) => Entrada(
        id: nuevoId,
        titulo: titulo,
        descripcion: descripcion,
        categoria: categoria,
        fecha: fecha,
        rutaImagen: rutaImagen,
        ubicacion: ubicacion,
      );

  @override
  bool operator ==(Object other) =>
      other is Entrada &&
      other.id == id &&
      other.titulo == titulo &&
      other.descripcion == descripcion &&
      other.categoria == categoria &&
      other.fecha == fecha &&
      other.rutaImagen == rutaImagen &&
      other.ubicacion == ubicacion;

  @override
  int get hashCode => Object.hash(
      id, titulo, descripcion, categoria, fecha, rutaImagen, ubicacion);
}

/// Tipos de registro que se pueden hacer en la bitácora de obra.
///
/// La entidad es pura (sin Flutter): el icono y el color de cada categoría se
/// definen en la capa de presentación (`categoria_visual.dart`).
enum CategoriaEntrada {
  avance('Avance de obra'),
  incidencia('Incidencia'),
  seguridad('Seguridad'),
  materiales('Materiales'),
  inspeccion('Inspección');

  const CategoriaEntrada(this.etiqueta);

  /// Nombre legible para mostrar en pantalla.
  final String etiqueta;

  /// Convierte el texto guardado en SQLite de vuelta a la categoría.
  /// Si el valor es desconocido (p. ej. datos corruptos) usa [avance].
  static CategoriaEntrada desdeNombre(String? nombre) => values.firstWhere(
        (categoria) => categoria.name == nombre,
        orElse: () => CategoriaEntrada.avance,
      );
}

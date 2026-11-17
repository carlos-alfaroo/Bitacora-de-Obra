import '../../dominio/entidades/categoria_entrada.dart';
import '../../dominio/entidades/entrada.dart';
import '../../dominio/entidades/ubicacion.dart';
import '../fuentes_locales/base_datos_local.dart';

/// Convierte entre la entidad [Entrada] y la fila de SQLite (`Map`).
///
/// Separar el mapeo mantiene la entidad de dominio libre de detalles
/// de almacenamiento (principio de responsabilidad única).
abstract final class MapeadorEntrada {
  static Map<String, Object?> aFila(Entrada entrada) => {
        // El id se omite al insertar para que SQLite lo genere.
        if (entrada.id != null) TablaEntradas.id: entrada.id,
        TablaEntradas.titulo: entrada.titulo,
        TablaEntradas.descripcion: entrada.descripcion,
        TablaEntradas.categoria: entrada.categoria.name,
        TablaEntradas.fecha: entrada.fecha.millisecondsSinceEpoch,
        TablaEntradas.rutaImagen: entrada.rutaImagen,
        TablaEntradas.latitud: entrada.ubicacion?.latitud,
        TablaEntradas.longitud: entrada.ubicacion?.longitud,
        TablaEntradas.precision: entrada.ubicacion?.precisionMetros,
      };

  /// Lanza [FormatException] si la fila no tiene los campos obligatorios.
  static Entrada desdeFila(Map<String, Object?> fila) {
    final id = fila[TablaEntradas.id];
    final fecha = fila[TablaEntradas.fecha];
    if (id is! int || fecha is! int) {
      throw FormatException('Fila de entrada inválida: $fila');
    }

    final latitud = (fila[TablaEntradas.latitud] as num?)?.toDouble();
    final longitud = (fila[TablaEntradas.longitud] as num?)?.toDouble();

    return Entrada(
      id: id,
      titulo: fila[TablaEntradas.titulo] as String? ?? '',
      descripcion: fila[TablaEntradas.descripcion] as String? ?? '',
      categoria:
          CategoriaEntrada.desdeNombre(fila[TablaEntradas.categoria] as String?),
      fecha: DateTime.fromMillisecondsSinceEpoch(fecha),
      rutaImagen: fila[TablaEntradas.rutaImagen] as String?,
      // Sólo hay ubicación si existen ambas coordenadas.
      ubicacion: (latitud != null && longitud != null)
          ? Ubicacion(
              latitud: latitud,
              longitud: longitud,
              precisionMetros:
                  (fila[TablaEntradas.precision] as num?)?.toDouble(),
            )
          : null,
    );
  }
}

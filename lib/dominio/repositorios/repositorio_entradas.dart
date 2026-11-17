import '../entidades/categoria_entrada.dart';
import '../entidades/entrada.dart';

/// Contrato de persistencia de las entradas de la bitácora.
///
/// La presentación depende de esta abstracción y no de SQLite
/// (principio de inversión de dependencias). Cambiar de motor de base de
/// datos sólo requiere una nueva implementación de esta interfaz.
///
/// Todas las operaciones lanzan `AlmacenamientoException` si fallan.
abstract interface class RepositorioEntradas {
  /// Devuelve las entradas, opcionalmente filtradas por [categoria].
  Future<List<Entrada>> obtenerTodas({
    CategoriaEntrada? categoria,
    bool recientesPrimero = true,
  });

  /// Devuelve la entrada con [id], o `null` si ya no existe.
  Future<Entrada?> obtenerPorId(int id);

  /// Guarda una entrada nueva y la devuelve con su `id` asignado.
  Future<Entrada> crear(Entrada entrada);

  /// Reemplaza los datos de una entrada existente (debe tener `id`).
  Future<void> actualizar(Entrada entrada);

  /// Elimina la entrada con [id].
  Future<void> eliminar(int id);

  /// Cantidad de entradas por categoría (para los contadores del Drawer).
  Future<Map<CategoriaEntrada, int>> contarPorCategoria();
}

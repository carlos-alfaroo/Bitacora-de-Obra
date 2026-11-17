import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Nombres de la tabla y columnas de SQLite, centralizados para evitar
/// errores de tipeo entre el esquema, las consultas y el mapeador.
abstract final class TablaEntradas {
  static const nombre = 'entradas';
  static const id = 'id';
  static const titulo = 'titulo';
  static const descripcion = 'descripcion';
  static const categoria = 'categoria';
  static const fecha = 'fecha'; // milisegundos desde epoch (INTEGER)
  static const rutaImagen = 'ruta_imagen';
  static const latitud = 'latitud';
  static const longitud = 'longitud';
  static const precision = 'precision_metros';
}

/// Abre (y crea la primera vez) la base de datos SQLite de la app.
///
/// Responsabilidad única: gestionar la conexión y el esquema. Las consultas
/// viven en el repositorio.
class BaseDatosLocal {
  /// [fabrica] y [ruta] permiten usar una base de datos en memoria en las
  /// pruebas; en la app real se usan los valores por defecto de sqflite.
  BaseDatosLocal({this.fabrica, this.ruta});

  static const nombreArchivo = 'bitacora_obra.db';
  static const version = 1;

  final DatabaseFactory? fabrica;
  final String? ruta;

  /// Se guarda el Future (no la conexión) para que dos llamadas simultáneas
  /// compartan la misma apertura en lugar de abrir dos conexiones.
  Future<Database>? _apertura;

  Future<Database> get baseDatos => _apertura ??= _abrir();

  Future<Database> _abrir() async {
    try {
      final fabricaEfectiva = fabrica ?? databaseFactory;
      final rutaEfectiva = ruta ??
          p.join(await fabricaEfectiva.getDatabasesPath(), nombreArchivo);
      return await fabricaEfectiva.openDatabase(
        rutaEfectiva,
        options: OpenDatabaseOptions(version: version, onCreate: _crearEsquema),
      );
    } catch (_) {
      // Si falla, se olvida el intento para poder reintentar después.
      _apertura = null;
      rethrow;
    }
  }

  Future<void> _crearEsquema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${TablaEntradas.nombre} (
        ${TablaEntradas.id}          INTEGER PRIMARY KEY AUTOINCREMENT,
        ${TablaEntradas.titulo}      TEXT    NOT NULL,
        ${TablaEntradas.descripcion} TEXT    NOT NULL,
        ${TablaEntradas.categoria}   TEXT    NOT NULL,
        ${TablaEntradas.fecha}       INTEGER NOT NULL,
        ${TablaEntradas.rutaImagen}  TEXT,
        ${TablaEntradas.latitud}     REAL,
        ${TablaEntradas.longitud}    REAL,
        ${TablaEntradas.precision}   REAL
      )
    ''');
    // Índice para que ordenar por fecha siga siendo rápido con muchos registros.
    await db.execute(
      'CREATE INDEX idx_entradas_fecha ON ${TablaEntradas.nombre}(${TablaEntradas.fecha})',
    );
  }

  Future<void> cerrar() async {
    final apertura = _apertura;
    _apertura = null;
    if (apertura != null) await (await apertura).close();
  }
}

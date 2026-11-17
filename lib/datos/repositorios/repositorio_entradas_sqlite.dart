import 'package:sqflite/sqflite.dart';

import '../../core/errores/excepciones.dart';
import '../../dominio/entidades/categoria_entrada.dart';
import '../../dominio/entidades/entrada.dart';
import '../../dominio/repositorios/repositorio_entradas.dart';
import '../fuentes_locales/base_datos_local.dart';
import '../modelos/mapeador_entrada.dart';

/// Implementación de [RepositorioEntradas] sobre SQLite (paquete sqflite).
class RepositorioEntradasSqlite implements RepositorioEntradas {
  RepositorioEntradasSqlite(this._fuente);

  final BaseDatosLocal _fuente;

  @override
  Future<List<Entrada>> obtenerTodas({
    CategoriaEntrada? categoria,
    bool recientesPrimero = true,
  }) =>
      _protegido('cargar las entradas', (db) async {
        final filas = await db.query(
          TablaEntradas.nombre,
          where: categoria == null ? null : '${TablaEntradas.categoria} = ?',
          whereArgs: categoria == null ? null : [categoria.name],
          orderBy: '${TablaEntradas.fecha} ${recientesPrimero ? 'DESC' : 'ASC'}',
        );
        return filas.map(MapeadorEntrada.desdeFila).toList();
      });

  @override
  Future<Entrada?> obtenerPorId(int id) =>
      _protegido('cargar la entrada', (db) async {
        final filas = await db.query(
          TablaEntradas.nombre,
          where: '${TablaEntradas.id} = ?',
          whereArgs: [id],
          limit: 1,
        );
        return filas.isEmpty ? null : MapeadorEntrada.desdeFila(filas.first);
      });

  @override
  Future<Entrada> crear(Entrada entrada) =>
      _protegido('guardar la entrada', (db) async {
        final id = await db.insert(
          TablaEntradas.nombre,
          MapeadorEntrada.aFila(entrada),
        );
        return entrada.copiarConId(id);
      });

  @override
  Future<void> actualizar(Entrada entrada) async {
    final id = entrada.id;
    if (id == null) {
      throw const AlmacenamientoException(
          'No se puede actualizar una entrada que no se ha guardado.');
    }
    await _protegido('actualizar la entrada', (db) async {
      final cambiadas = await db.update(
        TablaEntradas.nombre,
        MapeadorEntrada.aFila(entrada),
        where: '${TablaEntradas.id} = ?',
        whereArgs: [id],
      );
      if (cambiadas == 0) {
        throw const AlmacenamientoException('La entrada ya no existe.');
      }
    });
  }

  @override
  Future<void> eliminar(int id) => _protegido('eliminar la entrada', (db) {
        return db.delete(
          TablaEntradas.nombre,
          where: '${TablaEntradas.id} = ?',
          whereArgs: [id],
        );
      });

  @override
  Future<Map<CategoriaEntrada, int>> contarPorCategoria() =>
      _protegido('contar las entradas', (db) async {
        final filas = await db.rawQuery(
          'SELECT ${TablaEntradas.categoria} AS c, COUNT(*) AS n '
          'FROM ${TablaEntradas.nombre} GROUP BY ${TablaEntradas.categoria}',
        );
        return {
          for (final fila in filas)
            CategoriaEntrada.desdeNombre(fila['c'] as String?):
                (fila['n'] as num).toInt(),
        };
      });

  /// Ejecuta [accion] traduciendo cualquier error técnico a
  /// [AlmacenamientoException] con un mensaje entendible.
  Future<T> _protegido<T>(
    String operacion,
    Future<T> Function(Database db) accion,
  ) async {
    try {
      final db = await _fuente.baseDatos;
      return await accion(db);
    } on AlmacenamientoException {
      rethrow;
    } on DatabaseException catch (e) {
      throw AlmacenamientoException(
          'No se pudo $operacion en la base de datos.',
          causa: e);
    } on FormatException catch (e) {
      throw AlmacenamientoException(
          'Hay datos dañados en la base de datos al $operacion.',
          causa: e);
    } catch (e) {
      throw AlmacenamientoException('Error inesperado al $operacion.',
          causa: e);
    }
  }
}

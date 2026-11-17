import 'package:bitacora_obra/core/errores/excepciones.dart';
import 'package:bitacora_obra/datos/fuentes_locales/base_datos_local.dart';
import 'package:bitacora_obra/datos/repositorios/repositorio_entradas_sqlite.dart';
import 'package:bitacora_obra/dominio/entidades/categoria_entrada.dart';
import 'package:bitacora_obra/dominio/entidades/entrada.dart';
import 'package:bitacora_obra/dominio/entidades/ubicacion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Prueba el repositorio contra un SQLite real en memoria (sqflite_common_ffi),
/// con el mismo esquema que usa la app en el teléfono.
void main() {
  late BaseDatosLocal baseDatos;
  late RepositorioEntradasSqlite repositorio;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    baseDatos = BaseDatosLocal(fabrica: databaseFactoryFfi, ruta: inMemoryDatabasePath);
    repositorio = RepositorioEntradasSqlite(baseDatos);
  });

  tearDown(() => baseDatos.cerrar());

  Entrada nueva(String titulo, CategoriaEntrada categoria, DateTime fecha) => Entrada(
        titulo: titulo,
        descripcion: 'Descripción de $titulo',
        categoria: categoria,
        fecha: fecha,
        rutaImagen: '/imagenes/$titulo.jpg',
        ubicacion: const Ubicacion(latitud: 20.67, longitud: -103.35, precisionMetros: 12),
      );

  test('crear asigna id y obtenerPorId devuelve la misma entrada', () async {
    final creada = await repositorio
        .crear(nueva('Cimbra', CategoriaEntrada.avance, DateTime(2026, 11, 1)));

    expect(creada.id, isNotNull);
    expect(await repositorio.obtenerPorId(creada.id!), creada);
  });

  test('obtenerTodas ordena por fecha y filtra por categoría', () async {
    await repositorio.crear(nueva('A', CategoriaEntrada.avance, DateTime(2026, 11, 1)));
    await repositorio.crear(nueva('B', CategoriaEntrada.incidencia, DateTime(2026, 11, 3)));
    await repositorio.crear(nueva('C', CategoriaEntrada.avance, DateTime(2026, 11, 2)));

    final recientes = await repositorio.obtenerTodas();
    expect(recientes.map((e) => e.titulo), ['B', 'C', 'A']);

    final antiguas = await repositorio.obtenerTodas(recientesPrimero: false);
    expect(antiguas.map((e) => e.titulo), ['A', 'C', 'B']);

    final avances = await repositorio.obtenerTodas(categoria: CategoriaEntrada.avance);
    expect(avances.map((e) => e.titulo), ['C', 'A']);
  });

  test('actualizar reemplaza los datos', () async {
    final creada = await repositorio
        .crear(nueva('Original', CategoriaEntrada.avance, DateTime(2026, 11, 1)));
    final editada = Entrada(
      id: creada.id,
      titulo: 'Editada',
      descripcion: 'Nuevo texto',
      categoria: CategoriaEntrada.seguridad,
      fecha: creada.fecha,
    );

    await repositorio.actualizar(editada);

    expect(await repositorio.obtenerPorId(creada.id!), editada);
  });

  test('actualizar una entrada inexistente lanza AlmacenamientoException', () {
    final fantasma = nueva('X', CategoriaEntrada.avance, DateTime(2026)).copiarConId(999);
    expect(repositorio.actualizar(fantasma), throwsA(isA<AlmacenamientoException>()));
  });

  test('eliminar borra la entrada', () async {
    final creada = await repositorio
        .crear(nueva('Temporal', CategoriaEntrada.materiales, DateTime(2026, 11, 1)));

    await repositorio.eliminar(creada.id!);

    expect(await repositorio.obtenerPorId(creada.id!), isNull);
  });

  test('contarPorCategoria agrupa correctamente', () async {
    await repositorio.crear(nueva('A', CategoriaEntrada.avance, DateTime(2026, 11, 1)));
    await repositorio.crear(nueva('B', CategoriaEntrada.avance, DateTime(2026, 11, 2)));
    await repositorio.crear(nueva('C', CategoriaEntrada.seguridad, DateTime(2026, 11, 3)));

    expect(await repositorio.contarPorCategoria(), {
      CategoriaEntrada.avance: 2,
      CategoriaEntrada.seguridad: 1,
    });
  });

  test('un error de SQLite se traduce a AlmacenamientoException', () async {
    final db = await baseDatos.baseDatos;
    await db.execute('DROP TABLE ${TablaEntradas.nombre}');

    expect(repositorio.obtenerTodas(), throwsA(isA<AlmacenamientoException>()));
  });
}

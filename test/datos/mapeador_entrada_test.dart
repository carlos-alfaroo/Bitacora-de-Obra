import 'package:bitacora_obra/datos/fuentes_locales/base_datos_local.dart';
import 'package:bitacora_obra/datos/modelos/mapeador_entrada.dart';
import 'package:bitacora_obra/dominio/entidades/categoria_entrada.dart';
import 'package:bitacora_obra/dominio/entidades/entrada.dart';
import 'package:bitacora_obra/dominio/entidades/ubicacion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final entrada = Entrada(
    id: 7,
    titulo: 'Colado de losa',
    descripcion: 'Se coló la losa del nivel 2.',
    categoria: CategoriaEntrada.avance,
    fecha: DateTime(2026, 11, 17, 9, 30),
    rutaImagen: '/docs/imagenes/entrada_1.jpg',
    ubicacion: const Ubicacion(latitud: 19.43, longitud: -99.13, precisionMetros: 5),
  );

  test('ida y vuelta entidad → fila → entidad conserva todos los datos', () {
    final fila = MapeadorEntrada.aFila(entrada);
    expect(MapeadorEntrada.desdeFila(fila), entrada);
  });

  test('la fecha se guarda como milisegundos y la categoría como texto', () {
    final fila = MapeadorEntrada.aFila(entrada);
    expect(fila[TablaEntradas.fecha], entrada.fecha.millisecondsSinceEpoch);
    expect(fila[TablaEntradas.categoria], 'avance');
  });

  test('sin id no se incluye la columna id (SQLite la genera)', () {
    final nueva = Entrada(
      titulo: 't',
      descripcion: 'd',
      categoria: CategoriaEntrada.seguridad,
      fecha: DateTime(2026),
    );
    expect(MapeadorEntrada.aFila(nueva).containsKey(TablaEntradas.id), isFalse);
  });

  test('sin ambas coordenadas no hay ubicación', () {
    final fila = MapeadorEntrada.aFila(entrada)..[TablaEntradas.longitud] = null;
    expect(MapeadorEntrada.desdeFila(fila).ubicacion, isNull);
  });

  test('categoría desconocida usa el valor por defecto', () {
    final fila = MapeadorEntrada.aFila(entrada)..[TablaEntradas.categoria] = 'xyz';
    expect(MapeadorEntrada.desdeFila(fila).categoria, CategoriaEntrada.avance);
  });

  test('fila sin fecha lanza FormatException', () {
    final fila = MapeadorEntrada.aFila(entrada)..remove(TablaEntradas.fecha);
    expect(() => MapeadorEntrada.desdeFila(fila), throwsFormatException);
  });
}

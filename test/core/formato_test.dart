import 'package:bitacora_obra/core/utilidades/formato.dart';
import 'package:bitacora_obra/dominio/entidades/ubicacion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  final ahora = DateTime(2026, 11, 17, 18);

  test('fechaRelativa usa Hoy / Ayer / fecha corta', () {
    expect(Formato.fechaRelativa(DateTime(2026, 11, 17, 9, 5), ahora: ahora), 'Hoy, 09:05');
    expect(Formato.fechaRelativa(DateTime(2026, 11, 16, 23, 59), ahora: ahora), 'Ayer, 23:59');
    expect(Formato.fechaRelativa(DateTime(2026, 11, 3, 8, 30), ahora: ahora),
        startsWith('3 nov'));
  });

  test('fechaLarga está en español y con mayúscula inicial', () {
    expect(Formato.fechaLarga(DateTime(2026, 11, 17, 17, 45)),
        'Martes, 17 de noviembre de 2026 · 17:45');
  });

  test('coordenadas indica hemisferio', () {
    const cdmx = Ubicacion(latitud: 19.4326077, longitud: -99.133208);
    expect(Formato.coordenadas(cdmx), '19.43261° N, 99.13321° O');
  });
}

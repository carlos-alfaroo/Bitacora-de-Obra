import 'package:bitacora_obra/app.dart';
import 'package:bitacora_obra/core/errores/excepciones.dart';
import 'package:bitacora_obra/dominio/entidades/categoria_entrada.dart';
import 'package:bitacora_obra/dominio/entidades/entrada.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../fakes/fakes.dart';

/// Pruebas de widgets de la app completa (rutas, FutureBuilder, Drawer,
/// formulario y detalle) con los gadgets simulados.
void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  late DependenciasFalsas falsos;

  setUp(() => falsos = DependenciasFalsas());

  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(BitacoraApp(dependencias: falsos.dependencias));
    await tester.pumpAndSettle();
  }

  Future<void> llenarFormulario(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    // La categoría primero: al escribir, la lista se desplaza hacia el campo.
    await tester.tap(find.text('Seguridad'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'), 'Revisión de andamios');
    await tester.enterText(find.widgetWithText(TextFormField, 'Descripción'),
        'Andamio del eje B sin rodapié.');
  }

  /// Desplaza el formulario hasta que [objetivo] sea visible.
  Future<void> desplazarHasta(WidgetTester tester, Finder objetivo) =>
      tester.scrollUntilVisible(objetivo, 120,
          scrollable: find.byType(Scrollable).first);

  testWidgets('sin entradas muestra el estado vacío', (tester) async {
    await abrirApp(tester);
    expect(find.text('Tu bitácora está vacía'), findsOneWidget);
  });

  testWidgets('si SQLite falla se muestra el error y se puede reintentar',
      (tester) async {
    falsos.entradas.errorAlCargar =
        const AlmacenamientoException('Base de datos dañada');
    await abrirApp(tester);
    expect(find.text('Base de datos dañada'), findsOneWidget);

    falsos.entradas.errorAlCargar = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Tu bitácora está vacía'), findsOneWidget);
  });

  testWidgets('el formulario valida los campos obligatorios', (tester) async {
    await abrirApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar entrada'));
    await tester.pump();

    expect(find.text('Escribe un título'), findsOneWidget);
    expect(find.text('Escribe o dicta una descripción'), findsOneWidget);
    expect(falsos.entradas.entradas, isEmpty);
  });

  testWidgets('guardar captura el GPS y la entrada aparece en la lista',
      (tester) async {
    await abrirApp(tester);
    await llenarFormulario(tester);

    await tester.tap(find.text('Guardar entrada'));
    await tester.pumpAndSettle();

    expect(falsos.ubicacion.lecturas, 1);
    final guardada = falsos.entradas.entradas.single;
    expect(guardada.categoria, CategoriaEntrada.seguridad);
    expect(guardada.ubicacion, falsos.ubicacion.ubicacion);
    expect(find.text('Revisión de andamios'), findsOneWidget);
    expect(find.text('Entrada guardada en la bitácora'), findsOneWidget);
  });

  testWidgets('si el GPS falla se puede guardar sin ubicación', (tester) async {
    falsos.ubicacion.error = const UbicacionException(
        MotivoFalloUbicacion.permisoDenegado, 'Se negó el permiso de ubicación.');
    await abrirApp(tester);
    await llenarFormulario(tester);

    await tester.tap(find.text('Guardar entrada'));
    // Sin pumpAndSettle: el indicador de progreso del botón gira mientras
    // el diálogo espera respuesta.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('No se obtuvo la ubicación'), findsOneWidget);

    await tester.tap(find.text('Guardar sin GPS'));
    await tester.pumpAndSettle();

    expect(falsos.entradas.entradas.single.ubicacion, isNull);
  });

  testWidgets('el dictado se agrega al texto que ya había', (tester) async {
    await abrirApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción'), 'Llegó el cemento.');
    await desplazarHasta(tester, find.byTooltip('Dictar con el micrófono'));

    await tester.tap(find.byTooltip('Dictar con el micrófono'));
    await tester.pump();
    expect(find.text('Escuchando…'), findsOneWidget);
    expect(falsos.dictado.ultimoIdioma, 'es_MX');

    falsos.dictado.emitir('faltan diez bultos');
    await tester.pumpAndSettle();

    expect(find.text('Llegó el cemento. Faltan diez bultos'), findsOneWidget);
    expect(find.text('Escuchando…'), findsNothing);
  });

  testWidgets('el Drawer filtra por categoría', (tester) async {
    await falsos.entradas.crear(Entrada(
        titulo: 'Entrega de varilla',
        descripcion: 'Llegaron 2 toneladas.',
        categoria: CategoriaEntrada.materiales,
        fecha: DateTime(2026, 11, 16)));
    await falsos.entradas.crear(Entrada(
        titulo: 'Fuga en cisterna',
        descripcion: 'Se detectó una fuga.',
        categoria: CategoriaEntrada.incidencia,
        fecha: DateTime(2026, 11, 17)));
    await abrirApp(tester);
    expect(find.text('Entrega de varilla'), findsOneWidget);
    expect(find.text('Fuga en cisterna'), findsOneWidget);

    await tester.tap(find.byTooltip('Abrir menú de navegación'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(Drawer), matching: find.text('Incidencia')));
    await tester.pumpAndSettle();

    expect(find.text('Fuga en cisterna'), findsOneWidget);
    expect(find.text('Entrega de varilla'), findsNothing);
  });

  testWidgets('abrir el detalle y eliminar la entrada', (tester) async {
    await falsos.entradas.crear(Entrada(
        titulo: 'Inspección de cimbra',
        descripcion: 'Cimbra aprobada por el supervisor.',
        categoria: CategoriaEntrada.inspeccion,
        fecha: DateTime(2026, 11, 17, 10)));
    await abrirApp(tester);

    await tester.tap(find.text('Inspección de cimbra'));
    await tester.pumpAndSettle();
    expect(find.text('Cimbra aprobada por el supervisor.'), findsOneWidget);
    expect(find.text('Sin ubicación GPS'), findsOneWidget);

    await tester.tap(find.byTooltip('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(falsos.entradas.entradas, isEmpty);
    expect(find.text('Entrada eliminada'), findsOneWidget);
    expect(find.text('Tu bitácora está vacía'), findsOneWidget);
  });
}

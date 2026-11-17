import 'package:bitacora_obra/core/errores/excepciones.dart';
import 'package:bitacora_obra/dominio/entidades/preferencias.dart';
import 'package:bitacora_obra/presentacion/controladores/controlador_preferencias.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fakes.dart';

void main() {
  test('cambiar el tema notifica y persiste', () async {
    final repositorio = RepositorioPreferenciasFalso();
    final control = ControladorPreferencias(repositorio);
    var avisos = 0;
    control.addListener(() => avisos++);

    await control.cambiarModoTema(ModoTema.oscuro);

    expect(control.actuales.modoTema, ModoTema.oscuro);
    expect(repositorio.guardadas.modoTema, ModoTema.oscuro);
    expect(avisos, 1);
  });

  test('si guardar falla se revierte el cambio y se relanza el error', () async {
    final repositorio = RepositorioPreferenciasFalso()..fallarAlGuardar = true;
    final control = ControladorPreferencias(repositorio);

    await expectLater(
      control.cambiarOrden(recientesPrimero: false),
      throwsA(isA<AlmacenamientoException>()),
    );
    expect(control.actuales.recientesPrimero, isTrue);
  });
}

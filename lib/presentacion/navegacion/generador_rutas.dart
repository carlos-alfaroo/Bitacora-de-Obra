import 'package:flutter/material.dart';

import '../../dominio/entidades/entrada.dart';
import '../pantallas/acerca_de_pantalla.dart';
import '../pantallas/ajustes_pantalla.dart';
import '../pantallas/detalle_entrada_pantalla.dart';
import '../pantallas/formulario_entrada_pantalla.dart';
import '../pantallas/lista_entradas_pantalla.dart';
import '../pantallas/mapa_entradas_pantalla.dart';
import '../pantallas/visor_imagen_pantalla.dart';
import '../widgets/estado_mensaje.dart';
import 'rutas.dart';

/// Configuración de la navegación de la app.
///
/// - [tabla]: rutas sin argumentos (propiedad `routes` de MaterialApp).
/// - [generar]: rutas que reciben argumentos; además aplican una transición
///   animada propia (desvanecido + deslizamiento).
/// - [desconocida]: respaldo si se pide una ruta inexistente.
abstract final class GeneradorRutas {
  static final Map<String, WidgetBuilder> tabla = {
    Rutas.inicio: (_) => const ListaEntradasPantalla(),
    Rutas.ajustes: (_) => const AjustesPantalla(),
    Rutas.acercaDe: (_) => const AcercaDePantalla(),
  };

  static Route<dynamic>? generar(RouteSettings ajustes) {
    final argumentos = ajustes.arguments;
    return switch (ajustes.name) {
      Rutas.detalle when argumentos is Entrada => _animada(
          ajustes, DetalleEntradaPantalla(entradaInicial: argumentos)),
      Rutas.nueva => _animada(ajustes, const FormularioEntradaPantalla(),
          tipo: _Transicion.subir),
      Rutas.editar when argumentos is Entrada => _animada(
          ajustes, FormularioEntradaPantalla(entradaOriginal: argumentos),
          tipo: _Transicion.subir),
      Rutas.imagen when argumentos is ArgumentosVisorImagen => _animada(
          ajustes, VisorImagenPantalla(argumentos: argumentos),
          tipo: _Transicion.desvanecer),
      Rutas.mapa => _animada(ajustes,
          MapaEntradasPantalla(enfocar: argumentos is Entrada ? argumentos : null)),
      _ => null, // MaterialApp recurre a onUnknownRoute
    };
  }

  static Route<dynamic> desconocida(RouteSettings ajustes) => MaterialPageRoute(
        settings: ajustes,
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Página no encontrada')),
          body: EstadoMensaje(
            icono: Icons.explore_off_outlined,
            titulo: 'Ruta no encontrada',
            mensaje: 'La ruta «${ajustes.name}» no existe o le faltan datos.',
          ),
        ),
      );

  /// Ruta con transición personalizada. Hero funciona igual que con
  /// MaterialPageRoute porque PageRouteBuilder también es un PageRoute.
  static PageRouteBuilder<T> _animada<T>(
    RouteSettings ajustes,
    Widget pantalla, {
    _Transicion tipo = _Transicion.deslizar,
  }) {
    return PageRouteBuilder<T>(
      settings: ajustes,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => pantalla,
      transitionsBuilder: (context, animacion, _, hijo) {
        final curva = CurvedAnimation(
          parent: animacion,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final desvanecido = FadeTransition(opacity: curva, child: hijo);
        final desplazamiento = switch (tipo) {
          _Transicion.desvanecer => null,
          _Transicion.deslizar => const Offset(.08, 0),
          _Transicion.subir => const Offset(0, .06),
        };
        if (desplazamiento == null) return desvanecido;
        return SlideTransition(
          position: Tween(begin: desplazamiento, end: Offset.zero).animate(curva),
          child: desvanecido,
        );
      },
    );
  }
}

enum _Transicion { deslizar, subir, desvanecer }

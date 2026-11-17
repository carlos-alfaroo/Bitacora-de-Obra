import 'package:flutter/widgets.dart';

import '../../dominio/repositorios/repositorio_entradas.dart';
import '../../dominio/servicios/servicio_dictado.dart';
import '../../dominio/servicios/servicio_imagenes.dart';
import '../../dominio/servicios/servicio_mapas_externos.dart';
import '../../dominio/servicios/servicio_ubicacion.dart';
import '../controladores/controlador_preferencias.dart';

/// Conjunto de dependencias que usan las pantallas.
///
/// Todos los campos son **interfaces del dominio**: la presentación nunca
/// importa sqflite, geolocator, etc. Las implementaciones concretas se crean
/// en `main.dart` (raíz de composición) y en las pruebas se sustituyen por
/// versiones falsas.
class Dependencias {
  const Dependencias({
    required this.entradas,
    required this.ubicacion,
    required this.imagenes,
    required this.dictado,
    required this.mapasExternos,
    required this.preferencias,
  });

  final RepositorioEntradas entradas;
  final ServicioUbicacion ubicacion;
  final ServicioImagenes imagenes;
  final ServicioDictado dictado;
  final ServicioMapasExternos mapasExternos;
  final ControladorPreferencias preferencias;
}

/// Pone las [Dependencias] a disposición de todo el árbol de widgets.
class ProveedorDependencias extends InheritedWidget {
  const ProveedorDependencias({
    super.key,
    required this.dependencias,
    required super.child,
  });

  final Dependencias dependencias;

  static Dependencias of(BuildContext context) {
    // getInheritedWidgetOfExactType no registra dependencia (las
    // dependencias no cambian), por eso puede usarse desde initState.
    final proveedor =
        context.getInheritedWidgetOfExactType<ProveedorDependencias>();
    assert(proveedor != null, 'Falta ProveedorDependencias en el árbol.');
    return proveedor!.dependencias;
  }

  @override
  bool updateShouldNotify(ProveedorDependencias oldWidget) =>
      dependencias != oldWidget.dependencias;
}

/// Atajo: `context.dependencias.entradas`.
extension ContextoDependencias on BuildContext {
  Dependencias get dependencias => ProveedorDependencias.of(this);
}

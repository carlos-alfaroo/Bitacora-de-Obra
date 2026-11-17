import 'package:flutter/foundation.dart';

import '../../core/errores/excepciones.dart';
import '../../dominio/entidades/preferencias.dart';
import '../../dominio/repositorios/repositorio_preferencias.dart';

/// Mantiene las preferencias en memoria y avisa a la UI cuando cambian.
///
/// `MaterialApp` lo escucha para cambiar el tema al instante y la lista lo
/// escucha para reordenarse.
class ControladorPreferencias extends ChangeNotifier {
  ControladorPreferencias(this._repositorio,
      [Preferencias iniciales = const Preferencias()])
      : _actuales = iniciales;

  final RepositorioPreferencias _repositorio;
  Preferencias _actuales;

  Preferencias get actuales => _actuales;

  /// Lee las preferencias guardadas. Nunca lanza: si el almacenamiento
  /// falla, la app arranca con los valores por defecto.
  Future<void> cargar() async {
    try {
      _actuales = await _repositorio.cargar();
      notifyListeners();
    } on AlmacenamientoException catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> cambiarModoTema(ModoTema modo) =>
      _actualizar(_actuales.copiarCon(modoTema: modo));

  Future<void> cambiarOrden({required bool recientesPrimero}) =>
      _actualizar(_actuales.copiarCon(recientesPrimero: recientesPrimero));

  Future<void> cambiarIdiomaDictado(IdiomaDictado idioma) =>
      _actualizar(_actuales.copiarCon(idiomaDictado: idioma));

  /// Aplica el cambio de inmediato (la UI responde sin esperar al disco) y
  /// luego lo guarda. Si guardar falla, revierte y relanza el error para
  /// que la pantalla lo muestre.
  Future<void> _actualizar(Preferencias nuevas) async {
    final anteriores = _actuales;
    _actuales = nuevas;
    notifyListeners();
    try {
      await _repositorio.guardar(nuevas);
    } on AlmacenamientoException {
      _actuales = anteriores;
      notifyListeners();
      rethrow;
    }
  }
}

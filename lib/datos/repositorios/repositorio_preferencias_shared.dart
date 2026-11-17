import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errores/excepciones.dart';
import '../../dominio/entidades/preferencias.dart';
import '../../dominio/repositorios/repositorio_preferencias.dart';

/// Guarda las preferencias en SharedPreferences (pares clave-valor).
///
/// Se usa SharedPreferences y no SQLite porque son pocos valores simples
/// que no necesitan consultas; los registros de la bitácora sí van en SQLite.
class RepositorioPreferenciasShared implements RepositorioPreferencias {
  RepositorioPreferenciasShared([SharedPreferencesAsync? almacen])
      : _almacen = almacen ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _almacen;

  static const _claveTema = 'preferencias.tema';
  static const _claveRecientesPrimero = 'preferencias.recientes_primero';
  static const _claveIdiomaDictado = 'preferencias.idioma_dictado';

  @override
  Future<Preferencias> cargar() async {
    try {
      final tema = await _almacen.getString(_claveTema);
      final recientes = await _almacen.getBool(_claveRecientesPrimero);
      final idioma = await _almacen.getString(_claveIdiomaDictado);
      return Preferencias(
        modoTema: ModoTema.values.firstWhere(
          (modo) => modo.name == tema,
          orElse: () => ModoTema.sistema,
        ),
        recientesPrimero: recientes ?? true,
        idiomaDictado: IdiomaDictado.desdeCodigo(idioma),
      );
    } catch (e) {
      throw AlmacenamientoException('No se pudieron leer las preferencias.',
          causa: e);
    }
  }

  @override
  Future<void> guardar(Preferencias preferencias) async {
    try {
      await _almacen.setString(_claveTema, preferencias.modoTema.name);
      await _almacen.setBool(
          _claveRecientesPrimero, preferencias.recientesPrimero);
      await _almacen.setString(
          _claveIdiomaDictado, preferencias.idiomaDictado.codigo);
    } catch (e) {
      throw AlmacenamientoException('No se pudieron guardar las preferencias.',
          causa: e);
    }
  }
}

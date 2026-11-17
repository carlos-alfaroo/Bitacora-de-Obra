import '../entidades/preferencias.dart';

/// Contrato para leer y guardar las preferencias del usuario.
///
/// Lanza `AlmacenamientoException` si el almacenamiento falla.
abstract interface class RepositorioPreferencias {
  Future<Preferencias> cargar();
  Future<void> guardar(Preferencias preferencias);
}

import '../../core/errores/excepciones.dart';
import '../entidades/ubicacion.dart';

/// Gadget de geolocalización: obtiene la posición GPS del dispositivo.
abstract interface class ServicioUbicacion {
  /// Pide permiso si hace falta y devuelve la posición actual.
  ///
  /// Lanza [UbicacionException] indicando el [MotivoFalloUbicacion].
  Future<Ubicacion> obtenerUbicacionActual();

  /// Abre los ajustes del sistema adecuados para resolver [motivo]
  /// (activar el GPS o conceder el permiso de ubicación).
  Future<void> abrirAjustes(MotivoFalloUbicacion motivo);
}

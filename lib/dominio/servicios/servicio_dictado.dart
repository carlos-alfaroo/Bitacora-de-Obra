import '../../core/errores/excepciones.dart';

/// Recibe el texto reconocido. [esFinal] indica que la frase terminó.
typedef AlReconocerTexto = void Function(String texto, bool esFinal);

/// Gadget de audio: captura la voz por el micrófono y la convierte en texto.
abstract interface class ServicioDictado {
  /// Prepara el reconocedor y pide el permiso de micrófono.
  /// Devuelve `false` si el dispositivo no lo soporta o se negó el permiso.
  Future<bool> inicializar();

  bool get estaEscuchando;

  /// Empieza a escuchar en el idioma [codigoIdioma] (p. ej. `es_MX`).
  ///
  /// - [alReconocer]: resultados parciales y finales del dictado.
  /// - [alCambiarNivel]: volumen captado, normalizado entre 0 y 1.
  /// - [alTerminar]: el micrófono dejó de escuchar (silencio o [detener]).
  /// - [alError]: error durante la escucha.
  ///
  /// Lanza [DictadoException] si no se puede iniciar.
  Future<void> iniciar({
    required String codigoIdioma,
    required AlReconocerTexto alReconocer,
    void Function(double nivel)? alCambiarNivel,
    void Function()? alTerminar,
    void Function(DictadoException error)? alError,
  });

  /// Deja de escuchar y entrega el último resultado.
  Future<void> detener();

  /// Deja de escuchar descartando el resultado (al salir de la pantalla).
  Future<void> cancelar();
}

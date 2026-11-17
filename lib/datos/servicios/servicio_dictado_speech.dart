import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/errores/excepciones.dart';
import '../../dominio/servicios/servicio_dictado.dart';

/// Dictado por voz con el paquete speech_to_text.
///
/// El paquete captura el audio del micrófono y lo envía al reconocedor de
/// voz del sistema operativo (Google en Android, Apple en iOS), que devuelve
/// el texto transcrito en tiempo real.
class ServicioDictadoSpeechToText implements ServicioDictado {
  ServicioDictadoSpeechToText([SpeechToText? motor])
      : _motor = motor ?? SpeechToText();

  final SpeechToText _motor;
  bool _disponible = false;

  // Callbacks de la sesión de dictado activa.
  AlReconocerTexto? _alReconocer;
  void Function(double nivel)? _alCambiarNivel;
  void Function()? _alTerminar;
  void Function(DictadoException error)? _alError;

  @override
  bool get estaEscuchando => _motor.isListening;

  @override
  Future<bool> inicializar() async {
    if (_disponible) return true;
    try {
      // La primera vez el sistema muestra el diálogo de permiso de micrófono.
      _disponible = await _motor.initialize(
        onStatus: _alCambiarEstado,
        onError: _alOcurrirError,
      );
      return _disponible;
    } catch (e) {
      throw DictadoException('No se pudo iniciar el reconocimiento de voz.',
          causa: e);
    }
  }

  @override
  Future<void> iniciar({
    required String codigoIdioma,
    required AlReconocerTexto alReconocer,
    void Function(double nivel)? alCambiarNivel,
    void Function()? alTerminar,
    void Function(DictadoException error)? alError,
  }) async {
    if (!await inicializar()) {
      throw const DictadoException(
        'El dictado no está disponible: concede el permiso de micrófono o '
        'instala el servicio de voz de Google.',
      );
    }
    _alReconocer = alReconocer;
    _alCambiarNivel = alCambiarNivel;
    _alTerminar = alTerminar;
    _alError = alError;

    try {
      await _motor.listen(
        onResult: (resultado) =>
            _alReconocer?.call(resultado.recognizedWords, resultado.finalResult),
        onSoundLevelChange: (nivel) =>
            _alCambiarNivel?.call(_normalizarNivel(nivel)),
        listenOptions: SpeechListenOptions(
          localeId: codigoIdioma,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: true,
          listenFor: const Duration(minutes: 1),
          pauseFor: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      _limpiarSesion();
      throw DictadoException('No se pudo activar el micrófono.', causa: e);
    }
  }

  @override
  Future<void> detener() async {
    try {
      await _motor.stop();
    } catch (_) {
      // Si ya se había detenido no pasa nada.
    }
  }

  @override
  Future<void> cancelar() async {
    _limpiarSesion();
    try {
      await _motor.cancel();
    } catch (_) {}
  }

  void _alCambiarEstado(String estado) {
    if (estado == SpeechToText.doneStatus ||
        estado == SpeechToText.notListeningStatus) {
      _alTerminar?.call();
    }
  }

  void _alOcurrirError(SpeechRecognitionError error) {
    _alError?.call(DictadoException(_traducir(error.errorMsg), causa: error));
    _alTerminar?.call();
  }

  void _limpiarSesion() {
    _alReconocer = null;
    _alCambiarNivel = null;
    _alTerminar = null;
    _alError = null;
  }

  /// Android reporta el volumen en dB aprox. entre -2 y 10; se lleva a 0..1.
  double _normalizarNivel(double decibeles) =>
      ((decibeles + 2) / 12).clamp(0.0, 1.0);

  String _traducir(String codigo) => switch (codigo) {
        'error_no_match' => 'No se entendió lo que dijiste. Intenta de nuevo.',
        'error_speech_timeout' => 'No se detectó voz. Habla más cerca del micrófono.',
        'error_network' ||
        'error_network_timeout' =>
          'El dictado necesita internet o el paquete de idioma sin conexión.',
        'error_audio_error' => 'Hubo un problema al grabar el audio.',
        'error_permission' ||
        'error_insufficient_permissions' =>
          'Se negó el permiso de micrófono.',
        'error_busy' => 'El reconocedor de voz está ocupado. Espera un momento.',
        'error_language_not_supported' ||
        'error_language_unavailable' =>
          'El idioma elegido no está disponible para dictado.',
        _ => 'Error en el dictado ($codigo).',
      };
}

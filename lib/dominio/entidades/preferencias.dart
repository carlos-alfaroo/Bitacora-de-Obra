/// Tema visual elegido por el usuario (independiente de Flutter).
enum ModoTema { sistema, claro, oscuro }

/// Idiomas disponibles para el dictado por voz.
enum IdiomaDictado {
  espanolMexico('es_MX', 'Español (México)'),
  espanolEspana('es_ES', 'Español (España)'),
  espanolEstadosUnidos('es_US', 'Español (EE. UU.)'),
  inglesEstadosUnidos('en_US', 'English (US)');

  const IdiomaDictado(this.codigo, this.etiqueta);

  /// Código de idioma que entiende el reconocedor de voz.
  final String codigo;
  final String etiqueta;

  static IdiomaDictado desdeCodigo(String? codigo) => values.firstWhere(
        (idioma) => idioma.codigo == codigo,
        orElse: () => IdiomaDictado.espanolMexico,
      );
}

/// Preferencias del usuario que se guardan con SharedPreferences.
class Preferencias {
  const Preferencias({
    this.modoTema = ModoTema.sistema,
    this.recientesPrimero = true,
    this.idiomaDictado = IdiomaDictado.espanolMexico,
  });

  final ModoTema modoTema;

  /// Orden de la lista: `true` muestra primero las entradas más nuevas.
  final bool recientesPrimero;
  final IdiomaDictado idiomaDictado;

  Preferencias copiarCon({
    ModoTema? modoTema,
    bool? recientesPrimero,
    IdiomaDictado? idiomaDictado,
  }) =>
      Preferencias(
        modoTema: modoTema ?? this.modoTema,
        recientesPrimero: recientesPrimero ?? this.recientesPrimero,
        idiomaDictado: idiomaDictado ?? this.idiomaDictado,
      );
}

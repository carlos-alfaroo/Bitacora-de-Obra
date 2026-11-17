/// Coordenadas GPS capturadas al guardar una entrada.
class Ubicacion {
  const Ubicacion({
    required this.latitud,
    required this.longitud,
    this.precisionMetros,
  });

  final double latitud;
  final double longitud;

  /// Radio de incertidumbre reportado por el GPS, en metros.
  final double? precisionMetros;

  @override
  bool operator ==(Object other) =>
      other is Ubicacion &&
      other.latitud == latitud &&
      other.longitud == longitud &&
      other.precisionMetros == precisionMetros;

  @override
  int get hashCode => Object.hash(latitud, longitud, precisionMetros);

  @override
  String toString() => 'Ubicacion($latitud, $longitud ±$precisionMetros m)';
}

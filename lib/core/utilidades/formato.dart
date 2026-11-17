import 'package:intl/intl.dart';

import '../../dominio/entidades/ubicacion.dart';

/// Funciones de formato reutilizables (fechas y coordenadas en español).
///
/// Requiere haber llamado a `initializeDateFormatting('es_MX')` en `main`.
abstract final class Formato {
  static const _locale = 'es_MX';

  /// "lunes, 17 de noviembre de 2026 · 17:45"
  static String fechaLarga(DateTime fecha) {
    final dia = DateFormat("EEEE, d 'de' MMMM 'de' y", _locale).format(fecha);
    return '${_capitalizar(dia)} · ${hora(fecha)}';
  }

  /// "Hoy, 17:45" · "Ayer, 09:10" · "12 nov 2026, 08:30"
  static String fechaRelativa(DateTime fecha, {DateTime? ahora}) {
    final hoy = _soloFecha(ahora ?? DateTime.now());
    final diferencia = hoy.difference(_soloFecha(fecha)).inDays;
    final textoHora = hora(fecha);
    return switch (diferencia) {
      0 => 'Hoy, $textoHora',
      1 => 'Ayer, $textoHora',
      _ => '${DateFormat('d MMM y', _locale).format(fecha)}, $textoHora',
    };
  }

  static String hora(DateTime fecha) => DateFormat.Hm(_locale).format(fecha);

  /// "19.43261° N, 99.13321° O"
  static String coordenadas(Ubicacion ubicacion) {
    final lat = ubicacion.latitud;
    final lon = ubicacion.longitud;
    final ns = lat >= 0 ? 'N' : 'S';
    final eo = lon >= 0 ? 'E' : 'O';
    return '${lat.abs().toStringAsFixed(5)}° $ns, '
        '${lon.abs().toStringAsFixed(5)}° $eo';
  }

  /// "±8 m"
  static String precision(double metros) => '±${metros.round()} m';

  static DateTime _soloFecha(DateTime f) => DateTime(f.year, f.month, f.day);

  static String _capitalizar(String texto) => texto.isEmpty
      ? texto
      : texto[0].toUpperCase() + texto.substring(1);
}

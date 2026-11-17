import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../core/errores/excepciones.dart';
import '../../dominio/entidades/ubicacion.dart';
import '../../dominio/servicios/servicio_ubicacion.dart';

/// Obtiene la posición GPS con el paquete geolocator.
class ServicioUbicacionGeolocator implements ServicioUbicacion {
  const ServicioUbicacionGeolocator({
    this.tiempoMaximo = const Duration(seconds: 20),
  });

  /// Tiempo máximo de espera por una lectura nueva del GPS.
  final Duration tiempoMaximo;

  @override
  Future<Ubicacion> obtenerUbicacionActual() async {
    try {
      // 1. ¿Está encendido el GPS?
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const UbicacionException(
          MotivoFalloUbicacion.servicioDesactivado,
          'El GPS del dispositivo está desactivado. Actívalo para registrar '
          'dónde se hizo la entrada.',
        );
      }

      // 2. ¿Tenemos permiso? Si no, se solicita al usuario.
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied) {
        throw const UbicacionException(
          MotivoFalloUbicacion.permisoDenegado,
          'Se negó el permiso de ubicación.',
        );
      }
      if (permiso == LocationPermission.deniedForever) {
        throw const UbicacionException(
          MotivoFalloUbicacion.permisoDenegadoPermanente,
          'El permiso de ubicación está bloqueado. Concédelo desde los '
          'ajustes de la aplicación.',
        );
      }

      // 3. Lectura de alta precisión con tiempo límite.
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: tiempoMaximo,
        ),
      );
      return _aUbicacion(posicion);
    } on UbicacionException {
      rethrow;
    } on TimeoutException catch (e) {
      // Sin señal (p. ej. dentro de una construcción): se usa la última
      // posición conocida si el sistema tiene una.
      final ultima = await _ultimaPosicionConocida();
      if (ultima != null) return _aUbicacion(ultima);
      throw UbicacionException(
        MotivoFalloUbicacion.tiempoAgotado,
        'No hubo señal GPS en ${tiempoMaximo.inSeconds} s. Intenta en un '
        'lugar más despejado.',
        causa: e,
      );
    } on LocationServiceDisabledException catch (e) {
      throw UbicacionException(
        MotivoFalloUbicacion.servicioDesactivado,
        'El GPS se desactivó durante la lectura.',
        causa: e,
      );
    } on PermissionDeniedException catch (e) {
      throw UbicacionException(
        MotivoFalloUbicacion.permisoDenegado,
        'Se negó el permiso de ubicación.',
        causa: e,
      );
    } catch (e) {
      throw UbicacionException(
        MotivoFalloUbicacion.desconocido,
        'No se pudo obtener la ubicación.',
        causa: e,
      );
    }
  }

  @override
  Future<void> abrirAjustes(MotivoFalloUbicacion motivo) async {
    try {
      if (motivo == MotivoFalloUbicacion.servicioDesactivado) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (_) {
      // Abrir ajustes es una ayuda opcional: si falla no se interrumpe nada.
    }
  }

  Future<Position?> _ultimaPosicionConocida() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  Ubicacion _aUbicacion(Position posicion) => Ubicacion(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
        precisionMetros: posicion.accuracy,
      );
}

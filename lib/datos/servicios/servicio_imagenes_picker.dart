import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/errores/excepciones.dart';
import '../../dominio/servicios/servicio_imagenes.dart';

/// Cámara y galería con image_picker; los archivos se guardan con dart:io.
class ServicioImagenesPicker implements ServicioImagenes {
  ServicioImagenesPicker([ImagePicker? selector])
      : _selector = selector ?? ImagePicker();

  final ImagePicker _selector;

  static const _carpeta = 'imagenes';

  @override
  Future<String?> seleccionar(OrigenImagen origen) async {
    try {
      final archivo = await _selector.pickImage(
        source: switch (origen) {
          OrigenImagen.camara => ImageSource.camera,
          OrigenImagen.galeria => ImageSource.gallery,
        },
        preferredCameraDevice: CameraDevice.rear,
        // Se reduce la foto para no llenar el almacenamiento del teléfono.
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return archivo?.path; // null = el usuario canceló
    } on PlatformException catch (e) {
      throw MultimediaException(_mensajePara(e, origen), causa: e);
    } catch (e) {
      throw MultimediaException('No se pudo obtener la imagen.', causa: e);
    }
  }

  @override
  Future<String> guardarPermanente(String rutaTemporal) async {
    try {
      final documentos = await getApplicationDocumentsDirectory();
      final carpeta = Directory(p.join(documentos.path, _carpeta));
      await carpeta.create(recursive: true);

      final extension = p.extension(rutaTemporal).isEmpty
          ? '.jpg'
          : p.extension(rutaTemporal);
      final destino = p.join(
        carpeta.path,
        'entrada_${DateTime.now().millisecondsSinceEpoch}$extension',
      );
      final copia = await File(rutaTemporal).copy(destino);
      return copia.path;
    } on FileSystemException catch (e) {
      throw MultimediaException(
          'No se pudo guardar la imagen en el dispositivo.',
          causa: e);
    } catch (e) {
      throw MultimediaException('Error inesperado al guardar la imagen.',
          causa: e);
    }
  }

  @override
  Future<void> eliminar(String ruta) async {
    try {
      final archivo = File(ruta);
      if (await archivo.exists()) await archivo.delete();
    } on FileSystemException catch (e) {
      throw MultimediaException('No se pudo borrar la imagen anterior.',
          causa: e);
    }
  }

  String _mensajePara(PlatformException e, OrigenImagen origen) =>
      switch (e.code) {
        'camera_access_denied' =>
          'Se negó el permiso de cámara. Actívalo en los ajustes.',
        'photo_access_denied' =>
          'Se negó el acceso a la galería. Actívalo en los ajustes.',
        'no_available_camera' => 'Este dispositivo no tiene cámara disponible.',
        _ => origen == OrigenImagen.camara
            ? 'No se pudo abrir la cámara.'
            : 'No se pudo abrir la galería.',
      };
}

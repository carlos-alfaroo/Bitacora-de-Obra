import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'datos/fuentes_locales/base_datos_local.dart';
import 'datos/repositorios/repositorio_entradas_sqlite.dart';
import 'datos/repositorios/repositorio_preferencias_shared.dart';
import 'datos/servicios/servicio_dictado_speech.dart';
import 'datos/servicios/servicio_imagenes_picker.dart';
import 'datos/servicios/servicio_mapas_url_launcher.dart';
import 'datos/servicios/servicio_ubicacion_geolocator.dart';
import 'presentacion/controladores/controlador_preferencias.dart';
import 'presentacion/inyeccion/dependencias.dart';

/// Raíz de composición: el único lugar que conoce las implementaciones
/// concretas (SQLite, geolocator, image_picker…). El resto de la app sólo
/// ve las interfaces del dominio.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');

  final preferencias = ControladorPreferencias(RepositorioPreferenciasShared());
  await preferencias.cargar(); // si falla, usa los valores por defecto

  runApp(BitacoraApp(
    dependencias: Dependencias(
      entradas: RepositorioEntradasSqlite(BaseDatosLocal()),
      ubicacion: const ServicioUbicacionGeolocator(),
      imagenes: ServicioImagenesPicker(),
      dictado: ServicioDictadoSpeechToText(),
      mapasExternos: const ServicioMapasUrlLauncher(),
      preferencias: preferencias,
    ),
  ));
}

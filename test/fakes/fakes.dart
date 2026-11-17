// Implementaciones falsas de las interfaces del dominio para las pruebas.
// Gracias a la inversión de dependencias, las pantallas se prueban sin
// SQLite, GPS, cámara ni micrófono reales.

import 'package:bitacora_obra/core/errores/excepciones.dart';
import 'package:bitacora_obra/dominio/entidades/categoria_entrada.dart';
import 'package:bitacora_obra/dominio/entidades/entrada.dart';
import 'package:bitacora_obra/dominio/entidades/preferencias.dart';
import 'package:bitacora_obra/dominio/entidades/ubicacion.dart';
import 'package:bitacora_obra/dominio/repositorios/repositorio_entradas.dart';
import 'package:bitacora_obra/dominio/repositorios/repositorio_preferencias.dart';
import 'package:bitacora_obra/dominio/servicios/servicio_dictado.dart';
import 'package:bitacora_obra/dominio/servicios/servicio_imagenes.dart';
import 'package:bitacora_obra/dominio/servicios/servicio_mapas_externos.dart';
import 'package:bitacora_obra/dominio/servicios/servicio_ubicacion.dart';
import 'package:bitacora_obra/presentacion/controladores/controlador_preferencias.dart';
import 'package:bitacora_obra/presentacion/inyeccion/dependencias.dart';

class RepositorioEntradasFalso implements RepositorioEntradas {
  final List<Entrada> entradas = [];
  int _siguienteId = 1;

  /// Si tiene valor, obtenerTodas lanza este error.
  BitacoraException? errorAlCargar;

  @override
  Future<List<Entrada>> obtenerTodas({
    CategoriaEntrada? categoria,
    bool recientesPrimero = true,
  }) async {
    final error = errorAlCargar;
    if (error != null) throw error;
    final filtradas = entradas
        .where((e) => categoria == null || e.categoria == categoria)
        .toList()
      ..sort((a, b) => recientesPrimero
          ? b.fecha.compareTo(a.fecha)
          : a.fecha.compareTo(b.fecha));
    return filtradas;
  }

  @override
  Future<Entrada?> obtenerPorId(int id) async {
    for (final e in entradas) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<Entrada> crear(Entrada entrada) async {
    final guardada = entrada.copiarConId(_siguienteId++);
    entradas.add(guardada);
    return guardada;
  }

  @override
  Future<void> actualizar(Entrada entrada) async {
    final i = entradas.indexWhere((e) => e.id == entrada.id);
    entradas[i] = entrada;
  }

  @override
  Future<void> eliminar(int id) async => entradas.removeWhere((e) => e.id == id);

  @override
  Future<Map<CategoriaEntrada, int>> contarPorCategoria() async {
    final conteo = <CategoriaEntrada, int>{};
    for (final e in entradas) {
      conteo[e.categoria] = (conteo[e.categoria] ?? 0) + 1;
    }
    return conteo;
  }
}

class ServicioUbicacionFalso implements ServicioUbicacion {
  Ubicacion ubicacion =
      const Ubicacion(latitud: 19.4326, longitud: -99.1332, precisionMetros: 8);
  UbicacionException? error;
  int lecturas = 0;

  @override
  Future<Ubicacion> obtenerUbicacionActual() async {
    lecturas++;
    final e = error;
    if (e != null) throw e;
    return ubicacion;
  }

  @override
  Future<void> abrirAjustes(MotivoFalloUbicacion motivo) async {}
}

class ServicioImagenesFalso implements ServicioImagenes {
  String? rutaSeleccionada;
  final List<String> eliminadas = [];

  @override
  Future<String?> seleccionar(OrigenImagen origen) async => rutaSeleccionada;

  @override
  Future<String> guardarPermanente(String rutaTemporal) async =>
      'permanente/$rutaTemporal';

  @override
  Future<void> eliminar(String ruta) async => eliminadas.add(ruta);
}

class ServicioDictadoFalso implements ServicioDictado {
  AlReconocerTexto? _alReconocer;
  void Function()? _alTerminar;
  bool _escuchando = false;
  String? ultimoIdioma;

  /// Simula que el reconocedor entregó [texto].
  void emitir(String texto, {bool esFinal = true}) {
    _alReconocer?.call(texto, esFinal);
    if (esFinal) {
      _escuchando = false;
      _alTerminar?.call();
    }
  }

  @override
  bool get estaEscuchando => _escuchando;

  @override
  Future<bool> inicializar() async => true;

  @override
  Future<void> iniciar({
    required String codigoIdioma,
    required AlReconocerTexto alReconocer,
    void Function(double nivel)? alCambiarNivel,
    void Function()? alTerminar,
    void Function(DictadoException error)? alError,
  }) async {
    ultimoIdioma = codigoIdioma;
    _alReconocer = alReconocer;
    _alTerminar = alTerminar;
    _escuchando = true;
  }

  @override
  Future<void> detener() async {
    _escuchando = false;
    _alTerminar?.call();
  }

  @override
  Future<void> cancelar() async {
    _escuchando = false;
    _alReconocer = null;
    _alTerminar = null;
  }
}

class ServicioMapasFalso implements ServicioMapasExternos {
  Ubicacion? ultimaAbierta;

  @override
  Future<void> abrirEnGoogleMaps(Ubicacion ubicacion) async =>
      ultimaAbierta = ubicacion;
}

class RepositorioPreferenciasFalso implements RepositorioPreferencias {
  Preferencias guardadas = const Preferencias();
  bool fallarAlGuardar = false;

  @override
  Future<Preferencias> cargar() async => guardadas;

  @override
  Future<void> guardar(Preferencias preferencias) async {
    if (fallarAlGuardar) {
      throw const AlmacenamientoException('Disco lleno');
    }
    guardadas = preferencias;
  }
}

/// Agrupa todos los falsos para inspeccionarlos desde las pruebas.
class DependenciasFalsas {
  final entradas = RepositorioEntradasFalso();
  final ubicacion = ServicioUbicacionFalso();
  final imagenes = ServicioImagenesFalso();
  final dictado = ServicioDictadoFalso();
  final mapas = ServicioMapasFalso();
  final preferencias = ControladorPreferencias(RepositorioPreferenciasFalso());

  Dependencias get dependencias => Dependencias(
        entradas: entradas,
        ubicacion: ubicacion,
        imagenes: imagenes,
        dictado: dictado,
        mapasExternos: mapas,
        preferencias: preferencias,
      );
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errores/excepciones.dart';
import '../../core/utilidades/formato.dart';
import '../../dominio/entidades/categoria_entrada.dart';
import '../../dominio/entidades/entrada.dart';
import '../../dominio/entidades/ubicacion.dart';
import '../../dominio/servicios/servicio_imagenes.dart';
import '../inyeccion/dependencias.dart';
import '../navegacion/rutas.dart';
import '../tema/categoria_visual.dart';
import '../utilidades/mensajes.dart';
import '../widgets/panel_dictado.dart';
import '../widgets/selector_imagen.dart';

/// Formulario para crear una entrada nueva o editar una existente.
///
/// Integra los gadgets del dispositivo:
/// - Cámara / galería para la foto de evidencia.
/// - Micrófono para dictar la descripción (voz a texto).
/// - GPS: la posición se captura en el momento de guardar.
class FormularioEntradaPantalla extends StatefulWidget {
  const FormularioEntradaPantalla({super.key, this.entradaOriginal});

  /// `null` = entrada nueva; con valor = edición.
  final Entrada? entradaOriginal;

  bool get esEdicion => entradaOriginal != null;

  @override
  State<FormularioEntradaPantalla> createState() =>
      _FormularioEntradaPantallaState();
}

/// Opciones del diálogo que aparece si el GPS falla al guardar.
enum _DecisionGps { reintentar, abrirAjustes, continuarSinGps, cancelar }

class _FormularioEntradaPantallaState extends State<FormularioEntradaPantalla> {
  late final Dependencias _deps = context.dependencias;
  final _claveFormulario = GlobalKey<FormState>();

  late final _titulo = TextEditingController(text: widget.entradaOriginal?.titulo);
  late final _descripcion =
      TextEditingController(text: widget.entradaOriginal?.descripcion);
  late CategoriaEntrada _categoria =
      widget.entradaOriginal?.categoria ?? CategoriaEntrada.avance;

  /// Ruta de la foto mostrada. Si [_imagenEsNueva] es `true` todavía está en
  /// la caché temporal y se copiará al almacenamiento de la app al guardar.
  late String? _rutaImagen = widget.entradaOriginal?.rutaImagen;
  bool _imagenEsNueva = false;

  /// Al crear siempre se captura el GPS; al editar es opcional.
  late bool _capturarUbicacion =
      !widget.esEdicion || widget.entradaOriginal?.ubicacion == null;

  bool _guardando = false;
  String _estadoGuardado = '';

  // Estado del dictado.
  bool _escuchando = false;
  double _nivelSonido = 0;
  String _textoAntesDelDictado = '';

  @override
  void dispose() {
    // Si se sale escuchando, se apaga el micrófono y se descartan callbacks.
    _deps.dictado.cancelar();
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  bool get _hayCambios {
    final original = widget.entradaOriginal;
    if (original == null) {
      return _titulo.text.trim().isNotEmpty ||
          _descripcion.text.trim().isNotEmpty ||
          _rutaImagen != null;
    }
    return _titulo.text.trim() != original.titulo ||
        _descripcion.text.trim() != original.descripcion ||
        _categoria != original.categoria ||
        _rutaImagen != original.rutaImagen;
  }

  // ───────────────────────── Cámara y galería ─────────────────────────

  Future<void> _seleccionarImagen(OrigenImagen origen) async {
    try {
      final ruta = await _deps.imagenes.seleccionar(origen);
      if (ruta == null || !mounted) return; // el usuario canceló
      setState(() {
        _rutaImagen = ruta;
        _imagenEsNueva = true;
      });
    } on MultimediaException catch (e) {
      if (mounted) mostrarError(context, e.mensaje);
    }
  }

  void _quitarImagen() => setState(() {
        _rutaImagen = null;
        _imagenEsNueva = false;
      });

  // ───────────────────────── Micrófono (dictado) ─────────────────────────

  Future<void> _alternarDictado() async {
    if (_escuchando) {
      await _deps.dictado.detener(); // _alTerminarDictado actualiza la UI
      return;
    }
    FocusScope.of(context).unfocus();
    _textoAntesDelDictado = _descripcion.text;
    setState(() {
      _escuchando = true;
      _nivelSonido = 0;
    });
    try {
      await _deps.dictado.iniciar(
        codigoIdioma: _deps.preferencias.actuales.idiomaDictado.codigo,
        alReconocer: _insertarTextoDictado,
        alCambiarNivel: (nivel) {
          if (mounted) setState(() => _nivelSonido = nivel);
        },
        alTerminar: _alTerminarDictado,
        alError: (error) {
          if (mounted) mostrarError(context, error.mensaje);
        },
      );
    } on DictadoException catch (e) {
      _alTerminarDictado();
      if (mounted) mostrarError(context, e.mensaje);
    }
  }

  void _alTerminarDictado() {
    if (!mounted || !_escuchando) return;
    setState(() {
      _escuchando = false;
      _nivelSonido = 0;
    });
  }

  /// Agrega lo dictado después del texto que ya había en la descripción.
  /// Los resultados parciales se van reemplazando hasta que llega el final.
  void _insertarTextoDictado(String texto, bool esFinal) {
    if (!mounted || texto.isEmpty) return;
    final previo = _textoAntesDelDictado.trimRight();
    final iniciaOracion = previo.isEmpty || RegExp(r'[.!?]$').hasMatch(previo);
    final dictado = iniciaOracion ? texto[0].toUpperCase() + texto.substring(1) : texto;
    final combinado = previo.isEmpty ? dictado : '$previo $dictado';

    _descripcion.value = TextEditingValue(
      text: combinado,
      selection: TextSelection.collapsed(offset: combinado.length),
    );
    if (esFinal) _textoAntesDelDictado = combinado;
  }

  // ───────────────────────── Guardar (con GPS) ─────────────────────────

  void _cambiarEstado(String estado) {
    if (mounted) setState(() => _estadoGuardado = estado);
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (_escuchando) await _deps.dictado.detener();
    if (!mounted) return;
    if (!(_claveFormulario.currentState?.validate() ?? false)) {
      mostrarError(context, 'Revisa los campos marcados en rojo.');
      return;
    }
    FocusScope.of(context).unfocus();

    final original = widget.entradaOriginal;
    String? copiaSinGuardar; // foto copiada que aún no pertenece a una entrada
    setState(() => _guardando = true);

    try {
      // 1. Posición GPS actual.
      var ubicacion = original?.ubicacion;
      if (_capturarUbicacion) {
        _cambiarEstado('Obteniendo ubicación GPS…');
        final resultado = await _obtenerUbicacion();
        if (resultado.cancelado) return;
        ubicacion = resultado.ubicacion ?? ubicacion;
      }

      // 2. Foto: se copia de la caché temporal al almacenamiento de la app.
      var rutaFinal = _rutaImagen;
      if (rutaFinal != null && _imagenEsNueva) {
        _cambiarEstado('Guardando foto…');
        rutaFinal = copiaSinGuardar =
            await _deps.imagenes.guardarPermanente(rutaFinal);
      }

      // 3. Registro en SQLite.
      _cambiarEstado('Guardando entrada…');
      final entrada = Entrada(
        id: original?.id,
        titulo: _titulo.text.trim(),
        descripcion: _descripcion.text.trim(),
        categoria: _categoria,
        fecha: original?.fecha ?? DateTime.now(),
        rutaImagen: rutaFinal,
        ubicacion: ubicacion,
      );
      if (original == null) {
        await _deps.entradas.crear(entrada);
      } else {
        await _deps.entradas.actualizar(entrada);
      }
      copiaSinGuardar = null; // la foto ya pertenece a la entrada guardada

      // 4. Si se reemplazó o quitó la foto anterior, se borra el archivo viejo.
      final rutaAnterior = original?.rutaImagen;
      if (rutaAnterior != null && rutaAnterior != rutaFinal) {
        unawaited(_eliminarArchivo(rutaAnterior));
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        original == null ? ResultadoEntrada.creada : ResultadoEntrada.actualizada,
      );
    } on BitacoraException catch (e) {
      if (mounted) mostrarError(context, e.mensaje);
    } catch (e) {
      if (mounted) mostrarError(context, 'Error inesperado al guardar: $e');
    } finally {
      // Si SQLite falló después de copiar la foto, no se deja un archivo huérfano.
      final copia = copiaSinGuardar;
      if (copia != null) unawaited(_eliminarArchivo(copia));
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Intenta leer el GPS; si falla pregunta al usuario qué hacer.
  Future<({bool cancelado, Ubicacion? ubicacion})> _obtenerUbicacion() async {
    while (true) {
      try {
        final ubicacion = await _deps.ubicacion.obtenerUbicacionActual();
        return (cancelado: false, ubicacion: ubicacion);
      } on UbicacionException catch (e) {
        if (!mounted) return (cancelado: true, ubicacion: null);
        switch (await _preguntarPorGps(e)) {
          case _DecisionGps.reintentar:
            continue;
          case _DecisionGps.abrirAjustes:
            await _deps.ubicacion.abrirAjustes(e.motivo);
            continue;
          case _DecisionGps.continuarSinGps:
            return (cancelado: false, ubicacion: null);
          case _DecisionGps.cancelar || null:
            return (cancelado: true, ubicacion: null);
        }
      }
    }
  }

  Future<_DecisionGps?> _preguntarPorGps(UbicacionException error) {
    final conservaAnterior = widget.entradaOriginal?.ubicacion != null;
    return showDialog<_DecisionGps>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_off_outlined),
        title: const Text('No se obtuvo la ubicación'),
        content: Text(error.mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _DecisionGps.cancelar),
            child: const Text('Cancelar'),
          ),
          if (error.motivo.seResuelveEnAjustes)
            TextButton(
              onPressed: () => Navigator.pop(context, _DecisionGps.abrirAjustes),
              child: const Text('Abrir ajustes'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, _DecisionGps.continuarSinGps),
            child: Text(conservaAnterior ? 'Conservar anterior' : 'Guardar sin GPS'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _DecisionGps.reintentar),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarArchivo(String ruta) async {
    try {
      await _deps.imagenes.eliminar(ruta);
    } on MultimediaException catch (e) {
      debugPrint('$e');
    }
  }

  // ───────────────────────── Salir sin guardar ─────────────────────────

  Future<void> _alIntentarSalir(bool yaSalio, Object? _) async {
    if (yaSalio || _guardando) return;
    if (_escuchando) await _deps.dictado.detener();
    if (!_hayCambios) {
      if (mounted) Navigator.pop(context);
      return;
    }
    if (!mounted) return;
    final descartar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text('Lo que escribiste no se guardará.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true && mounted) Navigator.pop(context);
  }

  // ───────────────────────── Interfaz ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final idioma = _deps.preferencias.actuales.idiomaDictado.etiqueta;

    return PopScope(
      canPop: false, // se decide en _alIntentarSalir
      onPopInvokedWithResult: _alIntentarSalir,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.esEdicion ? 'Editar entrada' : 'Nueva entrada'),
        ),
        body: AbsorbPointer(
          absorbing: _guardando,
          child: Form(
            key: _claveFormulario,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                SelectorImagen(
                  rutaImagen: _rutaImagen,
                  alElegir: _seleccionarImagen,
                  alQuitar: _quitarImagen,
                ),
                const SizedBox(height: 20),
                Text('Categoría', style: tema.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final categoria in CategoriaEntrada.values)
                      ChoiceChip(
                        avatar: Icon(categoria.icono,
                            size: 18, color: categoria.colorEn(context)),
                        label: Text(categoria.etiqueta),
                        selected: _categoria == categoria,
                        onSelected: (_) => setState(() => _categoria = categoria),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titulo,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ej. Colado de losa, nivel 2',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (valor) => (valor == null || valor.trim().isEmpty)
                      ? 'Escribe un título'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descripcion,
                  minLines: 5,
                  maxLines: 12,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Qué se hizo, qué pasó, qué falta… o díctalo con el micrófono',
                    alignLabelWithHint: true,
                  ),
                  validator: (valor) => (valor == null || valor.trim().length < 3)
                      ? 'Escribe o dicta una descripción'
                      : null,
                ),
                const SizedBox(height: 12),
                PanelDictado(
                  escuchando: _escuchando,
                  nivel: _nivelSonido,
                  idioma: idioma,
                  alPresionar: _alternarDictado,
                ),
                const SizedBox(height: 20),
                _TarjetaUbicacion(
                  ubicacionOriginal: widget.entradaOriginal?.ubicacion,
                  esEdicion: widget.esEdicion,
                  capturar: _capturarUbicacion,
                  alCambiar: (valor) => setState(() => _capturarUbicacion = valor),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Icon(Icons.save_outlined),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _guardando ? _estadoGuardado : 'Guardar entrada',
                key: ValueKey(_guardando ? _estadoGuardado : 'guardar'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Explica qué pasará con la ubicación GPS al guardar.
class _TarjetaUbicacion extends StatelessWidget {
  const _TarjetaUbicacion({
    required this.ubicacionOriginal,
    required this.esEdicion,
    required this.capturar,
    required this.alCambiar,
  });

  final Ubicacion? ubicacionOriginal;
  final bool esEdicion;
  final bool capturar;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final original = ubicacionOriginal;

    if (!esEdicion) {
      return Card(
        color: esquema.primaryContainer.withValues(alpha: .45),
        child: const ListTile(
          leading: Icon(Icons.my_location),
          title: Text('Ubicación GPS automática'),
          subtitle: Text('Al guardar se registrará tu posición actual como '
              'prueba de dónde se hizo la entrada.'),
        ),
      );
    }
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.my_location),
        title: const Text('Actualizar ubicación GPS'),
        subtitle: Text(original == null
            ? 'Esta entrada no tiene ubicación registrada.'
            : 'Actual: ${Formato.coordenadas(original)}'),
        value: capturar,
        onChanged: alCambiar,
      ),
    );
  }
}

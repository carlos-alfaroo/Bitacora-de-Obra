import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/errores/excepciones.dart';
import '../../core/utilidades/formato.dart';
import '../../dominio/entidades/entrada.dart';
import '../../dominio/entidades/ubicacion.dart';
import '../inyeccion/dependencias.dart';
import '../navegacion/rutas.dart';
import '../utilidades/mensajes.dart';
import '../widgets/chip_categoria.dart';
import '../widgets/estado_mensaje.dart';
import '../widgets/imagen_entrada.dart';
import '../widgets/mapa_ubicacion.dart';

/// Detalle de una entrada: foto (Hero), descripción y mapa de ubicación.
class DetalleEntradaPantalla extends StatefulWidget {
  const DetalleEntradaPantalla({super.key, required this.entradaInicial});

  /// La entrada que se tocó en la lista. Se muestra de inmediato (para que
  /// el Hero tenga destino desde el primer cuadro) mientras se relee de SQLite.
  final Entrada entradaInicial;

  @override
  State<DetalleEntradaPantalla> createState() => _DetalleEntradaPantallaState();
}

class _DetalleEntradaPantallaState extends State<DetalleEntradaPantalla> {
  late final Dependencias _deps = context.dependencias;
  late Future<Entrada?> _futuroEntrada;

  int get _id => widget.entradaInicial.id!;

  @override
  void initState() {
    super.initState();
    _futuroEntrada = _deps.entradas.obtenerPorId(_id);
  }

  void _recargar() => setState(() {
        _futuroEntrada = _deps.entradas.obtenerPorId(_id);
      });

  Future<void> _editar(Entrada entrada) async {
    final resultado =
        await Navigator.pushNamed(context, Rutas.editar, arguments: entrada);
    if (!mounted || resultado != ResultadoEntrada.actualizada) return;
    _recargar();
    mostrarMensaje(context, 'Cambios guardados');
  }

  Future<void> _eliminar(Entrada entrada) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('¿Eliminar entrada?'),
        content: Text('Se borrará «${entrada.titulo}» y su foto. '
            'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      await _deps.entradas.eliminar(_id);
      final ruta = entrada.rutaImagen;
      if (ruta != null) {
        try {
          await _deps.imagenes.eliminar(ruta);
        } on MultimediaException catch (e) {
          // El registro ya se borró; un archivo huérfano no es crítico.
          debugPrint('$e');
        }
      }
      if (!mounted) return;
      Navigator.pop(context, ResultadoEntrada.eliminada);
    } on AlmacenamientoException catch (e) {
      if (mounted) mostrarError(context, e.mensaje);
    }
  }

  Future<void> _abrirGoogleMaps(Ubicacion ubicacion) async {
    try {
      await _deps.mapasExternos.abrirEnGoogleMaps(ubicacion);
    } on MapaExternoException catch (e) {
      if (mounted) mostrarError(context, e.mensaje);
    }
  }

  Future<void> _copiarCoordenadas(Ubicacion ubicacion) async {
    await Clipboard.setData(
        ClipboardData(text: '${ubicacion.latitud}, ${ubicacion.longitud}'));
    if (mounted) mostrarMensaje(context, 'Coordenadas copiadas', icono: Icons.copy);
  }

  void _abrirVisor(Entrada entrada) => Navigator.pushNamed(
        context,
        Rutas.imagen,
        arguments: ArgumentosVisorImagen(
          rutaImagen: entrada.rutaImagen!,
          etiquetaHero: entrada.etiquetaHero,
          titulo: entrada.titulo,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Entrada?>(
      future: _futuroEntrada,
      // initialData: se pinta la entrada recibida mientras llega la consulta.
      initialData: widget.entradaInicial,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError &&
            snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EstadoMensaje(
              icono: Icons.search_off,
              titulo: 'La entrada ya no existe',
              mensaje: 'Pudo haberse eliminado desde otra pantalla.',
            ),
          );
        }
        return _contenido(
          snapshot.data ?? widget.entradaInicial,
          error: snapshot.error,
        );
      },
    );
  }

  Widget _contenido(Entrada entrada, {Object? error}) {
    final tema = Theme.of(context);
    final ubicacion = entrada.ubicacion;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 320,
            leading: _BotonSobreImagen(
              icono: Icons.arrow_back,
              ayuda: 'Volver',
              alTocar: () => Navigator.maybePop(context),
            ),
            actions: [
              _BotonSobreImagen(
                icono: Icons.edit_outlined,
                ayuda: 'Editar',
                alTocar: () => _editar(entrada),
              ),
              _BotonSobreImagen(
                icono: Icons.delete_outline,
                ayuda: 'Eliminar',
                alTocar: () => _eliminar(entrada),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: GestureDetector(
                onTap: entrada.tieneImagen ? () => _abrirVisor(entrada) : null,
                child: Hero(
                  tag: entrada.etiquetaHero,
                  child: ImagenEntrada(
                    ruta: entrada.rutaImagen,
                    categoria: entrada.categoria,
                    tamanoIcono: 96,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error != null) _AvisoError(error: error, alReintentar: _recargar),
                  ChipCategoria(categoria: entrada.categoria),
                  const SizedBox(height: 12),
                  Text(entrada.titulo,
                      style: tema.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.event_outlined,
                        size: 18, color: tema.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(Formato.fechaLarga(entrada.fecha),
                          style: tema.textTheme.bodyMedium?.copyWith(
                              color: tema.colorScheme.onSurfaceVariant)),
                    ),
                  ]),
                  const Divider(height: 36),
                  _Seccion(
                    icono: Icons.notes_outlined,
                    titulo: 'Descripción',
                    child: SelectableText(entrada.descripcion,
                        style: tema.textTheme.bodyLarge?.copyWith(height: 1.5)),
                  ),
                  const SizedBox(height: 28),
                  _Seccion(
                    icono: Icons.place_outlined,
                    titulo: 'Ubicación',
                    child: ubicacion == null
                        ? const _SinUbicacion()
                        : _BloqueUbicacion(
                            ubicacion: ubicacion,
                            alAbrirGoogleMaps: () => _abrirGoogleMaps(ubicacion),
                            alCopiar: () => _copiarCoordenadas(ubicacion),
                            alAmpliar: () => Navigator.pushNamed(
                                context, Rutas.mapa,
                                arguments: entrada),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BloqueUbicacion extends StatelessWidget {
  const _BloqueUbicacion({
    required this.ubicacion,
    required this.alAbrirGoogleMaps,
    required this.alCopiar,
    required this.alAmpliar,
  });

  final Ubicacion ubicacion;
  final VoidCallback alAbrirGoogleMaps;
  final VoidCallback alCopiar;
  final VoidCallback alAmpliar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final precision = ubicacion.precisionMetros;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MapaUbicacion(ubicacion: ubicacion),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.gps_fixed, size: 18, color: tema.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              Formato.coordenadas(ubicacion) +
                  (precision == null ? '' : '  (${Formato.precision(precision)})'),
              style: tema.textTheme.bodyMedium,
            ),
          ),
          IconButton(
            tooltip: 'Copiar coordenadas',
            icon: const Icon(Icons.copy, size: 20),
            onPressed: alCopiar,
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: alAbrirGoogleMaps,
              icon: const Icon(Icons.directions_outlined),
              label: const Text('Abrir en Google Maps'),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: alAmpliar,
            icon: const Icon(Icons.open_in_full, size: 18),
            label: const Text('Ampliar'),
          ),
        ]),
      ],
    );
  }
}

class _SinUbicacion extends StatelessWidget {
  const _SinUbicacion();

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.location_off_outlined),
          title: const Text('Sin ubicación GPS'),
          subtitle: const Text(
              'No se pudo obtener la posición al guardar. Puedes registrarla '
              'editando la entrada.'),
        ),
      );
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.icono, required this.titulo, required this.child});

  final IconData icono;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Icon(icono, size: 20, color: tema.colorScheme.primary),
          const SizedBox(width: 8),
          Text(titulo,
              style: tema.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _AvisoError extends StatelessWidget {
  const _AvisoError({required this.error, required this.alReintentar});

  final Object error;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final mensaje = error is BitacoraException
        ? (error as BitacoraException).mensaje
        : '$error';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: esquema.errorContainer,
        child: ListTile(
          leading: Icon(Icons.sync_problem, color: esquema.onErrorContainer),
          title: Text('Mostrando datos sin actualizar',
              style: TextStyle(color: esquema.onErrorContainer)),
          subtitle:
              Text(mensaje, style: TextStyle(color: esquema.onErrorContainer)),
          trailing: TextButton(onPressed: alReintentar, child: const Text('Reintentar')),
        ),
      ),
    );
  }
}

/// Botón circular semitransparente, legible tanto sobre la foto como sobre
/// la barra ya contraída.
class _BotonSobreImagen extends StatelessWidget {
  const _BotonSobreImagen({
    required this.icono,
    required this.ayuda,
    required this.alTocar,
  });

  final IconData icono;
  final String ayuda;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(4),
        child: IconButton(
          tooltip: ayuda,
          onPressed: alTocar,
          icon: Icon(icono),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black45,
            foregroundColor: Colors.white,
          ),
        ),
      );
}

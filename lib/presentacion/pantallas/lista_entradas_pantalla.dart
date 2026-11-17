import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/errores/excepciones.dart';
import '../../dominio/entidades/categoria_entrada.dart';
import '../../dominio/entidades/entrada.dart';
import '../inyeccion/dependencias.dart';
import '../navegacion/rutas.dart';
import '../tema/categoria_visual.dart';
import '../utilidades/mensajes.dart';
import '../widgets/aparicion_escalonada.dart';
import '../widgets/drawer_principal.dart';
import '../widgets/estado_mensaje.dart';
import '../widgets/tarjeta_entrada.dart';

/// Pantalla principal: lista de entradas guardadas en SQLite.
class ListaEntradasPantalla extends StatefulWidget {
  const ListaEntradasPantalla({super.key});

  @override
  State<ListaEntradasPantalla> createState() => _ListaEntradasPantallaState();
}

class _ListaEntradasPantallaState extends State<ListaEntradasPantalla> {
  late final Dependencias _deps;

  /// El Future se guarda en el estado y sólo se reemplaza al recargar.
  /// Si se creara dentro de build(), cada redibujado repetiría la consulta.
  late Future<List<Entrada>> _futuroEntradas;

  CategoriaEntrada? _filtro;
  late bool _recientesPrimero;

  @override
  void initState() {
    super.initState();
    _deps = context.dependencias;
    _recientesPrimero = _deps.preferencias.actuales.recientesPrimero;
    _deps.preferencias.addListener(_alCambiarPreferencias);
    _futuroEntradas = _consultar();
  }

  @override
  void dispose() {
    _deps.preferencias.removeListener(_alCambiarPreferencias);
    super.dispose();
  }

  Future<List<Entrada>> _consultar() => _deps.entradas.obtenerTodas(
        categoria: _filtro,
        recientesPrimero: _recientesPrimero,
      );

  /// Lanza una nueva consulta y la entrega al FutureBuilder.
  Future<void> _recargar() async {
    final futuro = _consultar();
    // Llaves y no flecha: setState no debe recibir una función que devuelva
    // un Future (la asignación con => devolvería el Future).
    setState(() {
      _futuroEntradas = futuro;
    });
    try {
      await futuro;
    } catch (_) {
      // El FutureBuilder ya muestra el error en pantalla.
    }
  }

  void _alCambiarPreferencias() {
    final recientes = _deps.preferencias.actuales.recientesPrimero;
    if (recientes != _recientesPrimero) {
      _recientesPrimero = recientes;
      _recargar();
    }
  }

  void _filtrar(CategoriaEntrada? categoria) {
    if (categoria == _filtro) return;
    _filtro = categoria;
    _recargar();
  }

  Future<void> _crearEntrada() async {
    final resultado = await Navigator.pushNamed(context, Rutas.nueva);
    if (!mounted || resultado != ResultadoEntrada.creada) return;
    unawaited(_recargar());
    mostrarMensaje(context, 'Entrada guardada en la bitácora');
  }

  Future<void> _abrirDetalle(Entrada entrada) async {
    // Se decodifica la foto antes de navegar para que el Hero vuele con la
    // imagen ya lista y no aparezca un hueco en blanco.
    final ruta = entrada.rutaImagen;
    if (ruta != null) {
      try {
        await precacheImage(FileImage(File(ruta)), context)
            .timeout(const Duration(milliseconds: 400));
      } catch (_) {
        // Si tarda o falla, se navega igual: el detalle maneja el error.
      }
    }
    if (!mounted) return;
    final resultado =
        await Navigator.pushNamed(context, Rutas.detalle, arguments: entrada);
    if (!mounted) return;
    unawaited(_recargar()); // pudo editarse o eliminarse
    if (resultado == ResultadoEntrada.eliminada) {
      mostrarMensaje(context, 'Entrada eliminada', icono: Icons.delete_outline);
    }
  }

  void _abrirMapa() => Navigator.pushNamed(context, Rutas.mapa);

  @override
  Widget build(BuildContext context) {
    final filtro = _filtro;
    return Scaffold(
      appBar: AppBar(
        title: Text(filtro?.etiqueta ?? 'Bitácora de Obra'),
        actions: [
          if (filtro != null)
            IconButton(
              tooltip: 'Quitar filtro',
              icon: const Icon(Icons.filter_alt_off_outlined),
              onPressed: () => _filtrar(null),
            ),
          IconButton(
            tooltip: 'Mapa de entradas',
            icon: const Icon(Icons.map_outlined),
            onPressed: _abrirMapa,
          ),
        ],
      ),
      drawer: DrawerPrincipal(
        categoriaSeleccionada: filtro,
        alSeleccionarCategoria: _filtrar,
        alCrearEntrada: _crearEntrada,
        alAbrirMapa: _abrirMapa,
      ),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<List<Entrada>>(
          future: _futuroEntradas,
          builder: (context, snapshot) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _contenido(snapshot),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearEntrada,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Nueva entrada'),
      ),
    );
  }

  /// Decide qué mostrar según el estado del FutureBuilder.
  Widget _contenido(AsyncSnapshot<List<Entrada>> snapshot) {
    if (snapshot.hasError) {
      final error = snapshot.error;
      return EstadoMensaje(
        key: const ValueKey('error'),
        icono: Icons.error_outline,
        titulo: 'No se pudieron cargar las entradas',
        mensaje: error is BitacoraException ? error.mensaje : '$error',
        textoAccion: 'Reintentar',
        alAccionar: _recargar,
      );
    }

    final entradas = snapshot.data;
    if (entradas == null) {
      return const Center(
        key: ValueKey('cargando'),
        child: CircularProgressIndicator(),
      );
    }

    if (entradas.isEmpty) {
      final filtro = _filtro;
      return EstadoMensaje(
        key: ValueKey('vacio-$filtro'),
        icono: filtro?.icono ?? Icons.menu_book_outlined,
        titulo: filtro == null
            ? 'Tu bitácora está vacía'
            : 'Sin entradas de «${filtro.etiqueta}»',
        mensaje: 'Registra lo que pasa en la obra con foto, dictado por voz '
            'y ubicación GPS.',
        textoAccion: 'Nueva entrada',
        alAccionar: _crearEntrada,
      );
    }

    return _ListaEntradas(
      key: ValueKey('lista-$_filtro'),
      entradas: entradas,
      alTocar: _abrirDetalle,
    );
  }
}

class _ListaEntradas extends StatelessWidget {
  const _ListaEntradas({super.key, required this.entradas, required this.alTocar});

  final List<Entrada> entradas;
  final ValueChanged<Entrada> alTocar;

  @override
  Widget build(BuildContext context) {
    final conFoto = entradas.where((e) => e.tieneImagen).length;
    final conGps = entradas.where((e) => e.tieneUbicacion).length;
    final total = entradas.length;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      // Espacio inferior para que el FAB no tape la última tarjeta.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: total + 1,
      itemBuilder: (context, indice) {
        if (indice == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Text(
              '$total ${total == 1 ? 'entrada' : 'entradas'} · '
              '$conFoto con foto · $conGps con GPS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }
        final entrada = entradas[indice - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AparicionEscalonada(
            indice: indice - 1,
            child: TarjetaEntrada(
              entrada: entrada,
              alTocar: () => alTocar(entrada),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../dominio/entidades/categoria_entrada.dart';
import '../inyeccion/dependencias.dart';
import '../navegacion/rutas.dart';
import '../tema/categoria_visual.dart';

/// Menú lateral: filtros por categoría (con contadores) y accesos a las
/// demás secciones de la app.
class DrawerPrincipal extends StatefulWidget {
  const DrawerPrincipal({
    super.key,
    required this.categoriaSeleccionada,
    required this.alSeleccionarCategoria,
    required this.alCrearEntrada,
    required this.alAbrirMapa,
  });

  /// `null` significa «todas las entradas».
  final CategoriaEntrada? categoriaSeleccionada;
  final ValueChanged<CategoriaEntrada?> alSeleccionarCategoria;
  final VoidCallback alCrearEntrada;
  final VoidCallback alAbrirMapa;

  @override
  State<DrawerPrincipal> createState() => _DrawerPrincipalState();
}

class _DrawerPrincipalState extends State<DrawerPrincipal> {
  /// El Drawer se construye cada vez que se abre, así que los contadores
  /// siempre están al día.
  late final Future<Map<CategoriaEntrada, int>> _conteos =
      context.dependencias.entradas.contarPorCategoria();

  /// Cierra el Drawer y después ejecuta [accion].
  void _cerrarY(VoidCallback accion) {
    Navigator.pop(context);
    accion();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Drawer(
      child: FutureBuilder<Map<CategoriaEntrada, int>>(
        future: _conteos,
        builder: (context, snapshot) {
          final conteos = snapshot.data ?? const {};
          final total = conteos.values.fold(0, (suma, n) => suma + n);
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _Cabecera(total: snapshot.hasData ? total : null),
              _Seccion('Bitácora'),
              _Opcion(
                icono: Icons.view_agenda_outlined,
                texto: 'Todas las entradas',
                contador: snapshot.hasData ? total : null,
                seleccionada: widget.categoriaSeleccionada == null,
                alTocar: () => _cerrarY(() => widget.alSeleccionarCategoria(null)),
              ),
              for (final categoria in CategoriaEntrada.values)
                _Opcion(
                  icono: categoria.icono,
                  color: categoria.colorEn(context),
                  texto: categoria.etiqueta,
                  contador: snapshot.hasData ? (conteos[categoria] ?? 0) : null,
                  seleccionada: widget.categoriaSeleccionada == categoria,
                  alTocar: () =>
                      _cerrarY(() => widget.alSeleccionarCategoria(categoria)),
                ),
              if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                  child: Text('No se pudieron contar las entradas.',
                      style: TextStyle(color: tema.colorScheme.error)),
                ),
              const Divider(indent: 28, endIndent: 28),
              _Opcion(
                icono: Icons.add_a_photo_outlined,
                texto: 'Nueva entrada',
                alTocar: () => _cerrarY(widget.alCrearEntrada),
              ),
              _Opcion(
                icono: Icons.map_outlined,
                texto: 'Mapa de entradas',
                alTocar: () => _cerrarY(widget.alAbrirMapa),
              ),
              const Divider(indent: 28, endIndent: 28),
              _Opcion(
                icono: Icons.settings_outlined,
                texto: 'Ajustes',
                alTocar: () =>
                    _cerrarY(() => Navigator.pushNamed(context, Rutas.ajustes)),
              ),
              _Opcion(
                icono: Icons.info_outline,
                texto: 'Acerca de',
                alTocar: () =>
                    _cerrarY(() => Navigator.pushNamed(context, Rutas.acercaDe)),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.total});

  final int? total;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    // Contenedor de altura flexible (en lugar de DrawerHeader, que tiene altura
    // fija) para que el texto no se desborde con letra grande.
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.paddingOf(context).top + 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [esquema.primary, esquema.tertiary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: esquema.onPrimary.withValues(alpha: .2),
            child: Icon(Icons.engineering, size: 30, color: esquema.onPrimary),
          ),
          const SizedBox(height: 12),
          Text('Bitácora de Obra',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: esquema.onPrimary, fontWeight: FontWeight.w800)),
          Text(
            total == null
                ? 'Diario de campo con foto, voz y GPS'
                : '$total ${total == 1 ? 'entrada registrada' : 'entradas registradas'}',
            style: TextStyle(color: esquema.onPrimary.withValues(alpha: .85)),
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
        child: Text(texto,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icono,
    required this.texto,
    required this.alTocar,
    this.color,
    this.contador,
    this.seleccionada = false,
  });

  final IconData icono;
  final String texto;
  final VoidCallback alTocar;
  final Color? color;
  final int? contador;
  final bool seleccionada;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        leading: Icon(icono, color: color),
        title: Text(texto),
        trailing: contador == null ? null : Text('$contador'),
        selected: seleccionada,
        selectedTileColor:
            Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: .7),
        shape: const StadiumBorder(),
        onTap: alTocar,
      ),
    );
  }
}

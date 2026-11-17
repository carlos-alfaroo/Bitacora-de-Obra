import 'package:flutter/material.dart';

import '../../core/errores/excepciones.dart';
import '../../dominio/entidades/preferencias.dart';
import '../controladores/controlador_preferencias.dart';
import '../inyeccion/dependencias.dart';
import '../utilidades/mensajes.dart';

/// Preferencias del usuario, guardadas con SharedPreferences.
class AjustesPantalla extends StatelessWidget {
  const AjustesPantalla({super.key});

  /// Ejecuta un cambio y avisa si no se pudo guardar.
  Future<void> _aplicar(BuildContext context, Future<void> Function() cambio) async {
    try {
      await cambio();
    } on AlmacenamientoException catch (e) {
      if (context.mounted) mostrarError(context, e.mensaje);
    }
  }

  Future<void> _elegirIdioma(
      BuildContext context, ControladorPreferencias control) async {
    final actual = control.actuales.idiomaDictado;
    final elegido = await showDialog<IdiomaDictado>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Idioma del dictado'),
        children: [
          for (final idioma in IdiomaDictado.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, idioma),
              child: Row(children: [
                Icon(idioma == actual ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(idioma.etiqueta),
              ]),
            ),
        ],
      ),
    );
    if (elegido != null && context.mounted) {
      await _aplicar(context, () => control.cambiarIdiomaDictado(elegido));
    }
  }

  @override
  Widget build(BuildContext context) {
    final control = context.dependencias.preferencias;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListenableBuilder(
        listenable: control,
        builder: (context, _) {
          final preferencias = control.actuales;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              const _Encabezado('Apariencia'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<ModoTema>(
                  segments: const [
                    ButtonSegment(
                        value: ModoTema.sistema,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('Sistema')),
                    ButtonSegment(
                        value: ModoTema.claro,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Claro')),
                    ButtonSegment(
                        value: ModoTema.oscuro,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Oscuro')),
                  ],
                  selected: {preferencias.modoTema},
                  onSelectionChanged: (seleccion) => _aplicar(
                      context, () => control.cambiarModoTema(seleccion.first)),
                ),
              ),
              const _Encabezado('Bitácora'),
              SwitchListTile(
                secondary: const Icon(Icons.sort),
                title: const Text('Más recientes primero'),
                subtitle: const Text('Orden de la lista de entradas'),
                value: preferencias.recientesPrimero,
                onChanged: (valor) => _aplicar(
                    context, () => control.cambiarOrden(recientesPrimero: valor)),
              ),
              const _Encabezado('Dictado por voz'),
              ListTile(
                leading: const Icon(Icons.record_voice_over_outlined),
                title: const Text('Idioma del dictado'),
                subtitle: Text(preferencias.idiomaDictado.etiqueta),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _elegirIdioma(context, control),
              ),
              const _Encabezado('Almacenamiento'),
              const ListTile(
                leading: Icon(Icons.storage_outlined),
                title: Text('Todo se guarda en el teléfono'),
                subtitle: Text('Las entradas, rutas de fotos y coordenadas se '
                    'guardan en SQLite; estos ajustes, en SharedPreferences. '
                    'La app funciona sin conexión.'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(texto,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700)),
      );
}

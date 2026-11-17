import 'package:flutter/material.dart';

/// Explica qué problema resuelve la app y cómo usa cada gadget.
class AcercaDePantalla extends StatelessWidget {
  const AcercaDePantalla({super.key});

  static const _soluciones = [
    (
      Icons.photo_camera_outlined,
      'Evidencia fotográfica',
      'Cada registro puede llevar una foto tomada con la cámara o elegida de '
          'la galería, ligada al texto y a la fecha.',
    ),
    (
      Icons.mic_none_rounded,
      'Dictado manos libres',
      'En obra se trabaja con guantes y prisa: la descripción se dicta con el '
          'micrófono y se convierte en texto al momento.',
    ),
    (
      Icons.location_on_outlined,
      'Prueba de lugar',
      'Al guardar se registra la posición GPS. El detalle la muestra en un '
          'mapa interactivo y permite abrirla en Google Maps.',
    ),
    (
      Icons.cloud_off_outlined,
      'Funciona sin señal',
      'Todo se guarda localmente en SQLite, así que no depende de internet '
          'en sitios sin cobertura.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.engineering, size: 64, color: tema.colorScheme.primary),
          const SizedBox(height: 12),
          Text('Bitácora de Obra',
              textAlign: TextAlign.center,
              style: tema.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text('Versión 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(color: tema.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          Text(
            'Las bitácoras de obra en papel se mojan, se pierden y no tienen '
            'evidencia confiable de cuándo y dónde ocurrió cada cosa. Esta app '
            'convierte el teléfono del residente o supervisor en un diario de '
            'campo digital.',
            style: tema.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 20),
          for (final (icono, titulo, texto) in _soluciones)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(icono, color: tema.colorScheme.primary, size: 28),
                  title: Text(titulo,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(texto),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Mapas © OpenStreetMap contributors.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodySmall
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

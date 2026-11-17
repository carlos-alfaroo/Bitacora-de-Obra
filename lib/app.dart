import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'presentacion/inyeccion/dependencias.dart';
import 'presentacion/navegacion/generador_rutas.dart';
import 'presentacion/navegacion/rutas.dart';
import 'presentacion/tema/tema_app.dart';

/// Widget raíz: provee las dependencias, aplica el tema elegido y
/// configura la navegación por rutas nombradas.
class BitacoraApp extends StatelessWidget {
  const BitacoraApp({super.key, required this.dependencias});

  final Dependencias dependencias;

  @override
  Widget build(BuildContext context) {
    return ProveedorDependencias(
      dependencias: dependencias,
      // Se reconstruye cuando cambia una preferencia (p. ej. el tema).
      child: ListenableBuilder(
        listenable: dependencias.preferencias,
        builder: (context, _) => MaterialApp(
          title: 'Bitácora de Obra',
          debugShowCheckedModeBanner: false,
          theme: TemaApp.claro,
          darkTheme: TemaApp.oscuro,
          themeMode: dependencias.preferencias.actuales.modoTema.aThemeMode,
          locale: const Locale('es', 'MX'),
          supportedLocales: const [Locale('es', 'MX'), Locale('es'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          initialRoute: Rutas.inicio,
          routes: GeneradorRutas.tabla,
          onGenerateRoute: GeneradorRutas.generar,
          onUnknownRoute: GeneradorRutas.desconocida,
        ),
      ),
    );
  }
}

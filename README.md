# Bitácora de Obra

Diario de campo para residentes y supervisores de obra, hecho con Flutter. Cada entrada registra **qué pasó** (texto escrito o dictado), **con qué evidencia** (foto de la cámara o la galería), **dónde** (GPS) y **cuándo**. Todo se guarda en el teléfono y funciona sin conexión.

> Proyecto del Parcial 2 de MO2: UI avanzada y navegación, almacenamiento local con manejo de errores y uso de gadgets del dispositivo.
>
> Reporte técnico (arquitectura, diagramas de clases y flujo de datos, justificación): [docs/Reporte_Tecnico_Bitacora_de_Obra.pdf](docs/Reporte_Tecnico_Bitacora_de_Obra.pdf)

## Problema que resuelve

Las bitácoras de obra en papel se mojan y se pierden, y no dejan una evidencia confiable de cuándo y dónde pasó cada cosa. Además, en obra se trabaja con guantes y con prisa, así que escribir en el teléfono es lento. La app atiende cada uno de esos problemas:

| Problema en obra | Solución en la app | Gadget |
|---|---|---|
| No hay evidencia visual | Foto adjunta a cada entrada | Cámara / galería |
| Escribir con guantes es lento | Dictado de voz a texto | Micrófono |
| No se puede probar dónde se hizo el registro | Coordenadas GPS capturadas al guardar, mapa y Google Maps | GPS |
| Sin señal en sitio | SQLite local, no requiere internet para guardar | — |

## Cómo se cumple cada requisito

| Requisito | Dónde está |
|---|---|
| Scaffold, AppBar y Drawer | [lista_entradas_pantalla.dart](lib/presentacion/pantallas/lista_entradas_pantalla.dart), [drawer_principal.dart](lib/presentacion/widgets/drawer_principal.dart) |
| Rutas nombradas y Navigator | [rutas.dart](lib/presentacion/navegacion/rutas.dart), [generador_rutas.dart](lib/presentacion/navegacion/generador_rutas.dart) (`routes` + `onGenerateRoute` + `onUnknownRoute`) |
| Lista → detalle → formulario | `Navigator.pushNamed` con argumentos y `Navigator.pop` con resultado (`ResultadoEntrada`) |
| Hero y widgets animados | `Hero` en [tarjeta_entrada.dart](lib/presentacion/widgets/tarjeta_entrada.dart), el detalle y [visor_imagen_pantalla.dart](lib/presentacion/pantallas/visor_imagen_pantalla.dart); `AnimatedSwitcher`, `AnimatedContainer`, `TweenAnimationBuilder` y transiciones con `PageRouteBuilder` |
| SQLite | [base_datos_local.dart](lib/datos/fuentes_locales/base_datos_local.dart), [repositorio_entradas_sqlite.dart](lib/datos/repositorios/repositorio_entradas_sqlite.dart): texto, categoría, fecha, **ruta de imagen** y **coordenadas** |
| SharedPreferences | [repositorio_preferencias_shared.dart](lib/datos/repositorios/repositorio_preferencias_shared.dart): tema, orden e idioma del dictado |
| try-catch | Cada servicio traduce los errores de su paquete a una [`BitacoraException`](lib/core/errores/excepciones.dart) sellada; la UI los muestra en SnackBars, diálogos o estados de error |
| FutureBuilder | Lista, detalle (con `initialData` para el Hero), mapa general y contadores del Drawer |
| Cámara y galería | [servicio_imagenes_picker.dart](lib/datos/servicios/servicio_imagenes_picker.dart) (`image_picker`) |
| Micrófono / voz a texto | [servicio_dictado_speech.dart](lib/datos/servicios/servicio_dictado_speech.dart) (`speech_to_text`), con nivel de audio en vivo |
| GPS al guardar | [servicio_ubicacion_geolocator.dart](lib/datos/servicios/servicio_ubicacion_geolocator.dart) (`geolocator`) |
| Mapa interactivo y Google Maps | [mapa_ubicacion.dart](lib/presentacion/widgets/mapa_ubicacion.dart) (`flutter_map` + OpenStreetMap) y [servicio_mapas_url_launcher.dart](lib/datos/servicios/servicio_mapas_url_launcher.dart) (`url_launcher`) |

## Arquitectura

El código está organizado en tres capas más un núcleo compartido. Las dependencias apuntan hacia el dominio.

```
lib/
├── main.dart                 Raíz de composición: crea las implementaciones concretas
├── app.dart                  MaterialApp, tema, rutas
├── core/                     Excepciones y utilidades de formato (sin Flutter)
├── dominio/                  Entidades e INTERFACES (sin Flutter ni paquetes)
│   ├── entidades/            Entrada, Ubicacion, CategoriaEntrada, Preferencias
│   ├── repositorios/         RepositorioEntradas, RepositorioPreferencias
│   └── servicios/            ServicioUbicacion, ServicioImagenes, ServicioDictado, ServicioMapasExternos
├── datos/                    IMPLEMENTACIONES con paquetes externos
│   ├── fuentes_locales/      BaseDatosLocal (sqflite)
│   ├── modelos/              MapeadorEntrada (entidad ↔ fila SQLite)
│   ├── repositorios/         ...Sqlite, ...Shared
│   └── servicios/            geolocator, image_picker, speech_to_text, url_launcher
└── presentacion/             Pantallas, widgets, navegación, tema
    ├── inyeccion/            Dependencias + ProveedorDependencias (InheritedWidget)
    ├── controladores/        ControladorPreferencias (ChangeNotifier)
    ├── navegacion/           Rutas y GeneradorRutas
    ├── pantallas/            Lista, Detalle, Formulario, Mapa, Ajustes, Acerca de, Visor
    └── widgets/              Componentes reutilizables
```

Principios SOLID aplicados:

- **S (responsabilidad única):** `BaseDatosLocal` sólo abre la base y crea el esquema, `MapeadorEntrada` sólo convierte datos y el repositorio sólo hace consultas. Cada gadget tiene su propio servicio.
- **O (abierto/cerrado):** para cambiar SQLite por otro motor o OpenStreetMap por Google Maps se agrega una implementación nueva, sin tocar las pantallas.
- **L (sustitución de Liskov):** las pruebas reemplazan cada servicio por una versión falsa y la app funciona igual.
- **I (segregación de interfaces):** son interfaces pequeñas y separadas por gadget, en vez de un "servicio del dispositivo" gigante.
- **D (inversión de dependencias):** la presentación depende de interfaces del dominio. Sólo `main.dart` importa la capa de datos.

## Ejecutar

Requisitos: Flutter 3.44 o superior (Dart 3.12). En Android, un dispositivo con Google Play Services para el dictado; en iOS, Xcode 26 o superior.

```bash
flutter pub get
flutter run            # dispositivo conectado
flutter test           # 26 pruebas de unidad y de widgets
flutter build apk      # APK de release
```

En iOS no hace falta CocoaPods: el proyecto usa Swift Package Manager (`enable-swift-package-manager` en `pubspec.yaml`). Para un iPhone físico, la primera vez abre `ios/Runner.xcworkspace` en Xcode y elige tu equipo en *Runner → Signing & Capabilities → Team*. Para usar la app sin la Mac conectada, instálala con `flutter run --release`.

Notas:

- El dictado usa el reconocedor de voz del sistema (Google en Android, Apple en iOS). Sin internet funciona si el paquete de idioma sin conexión está descargado.
- El mapa necesita internet para descargar las teselas. Las coordenadas se guardan siempre, aunque no haya conexión.
- En el emulador puedes simular la ubicación desde *Extended controls → Location*.

## Pruebas

- `test/datos/`: el mapeador y el repositorio contra **SQLite real en memoria** (`sqflite_common_ffi`).
- `test/core/`: el formato de fechas y coordenadas en español.
- `test/presentacion/`: el controlador de preferencias y los **flujos completos de la app** con gadgets simulados (guardar con GPS, guardar sin GPS, dictado, filtro del Drawer, detalle y eliminación).

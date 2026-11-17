# Identidad y pantalla de inicio de Higea Fitness

Se requieren tres imágenes oficiales dentro de `assets/branding/`:

- `higea_icon.png`: ícono cuadrado para el escritorio Android.
- `higea_icon_foreground.png`: imagen PNG transparente para ícono adaptable.
- `higea_splash.png`: composición Higea Fitness con panel de gestión.

Los PNG aprobados se entregan en el ZIP de recursos para descomprimir
en la raíz de `gym-system-management-lite` antes de compilar.

Después de generar los archivos Android con Flutter, ejecutar:

```bash
flutter pub get
dart run flutter_launcher_icons
dart run tool/configurar_splash.dart
flutter analyze --no-fatal-infos
flutter test
flutter run
```

El ícono nativo muestra la marca al abrir Android. Durante la carga de
SQLite, Flutter puede mostrar la composición completa de Higea Fitness.
No hay tiempo de espera artificial; en un teléfono rápido el poster puede
verse brevemente. Android 12+ restringe su splash nativo a un ícono
central y color de fondo; por eso el poster se muestra al iniciar Flutter.

El script también escribe `Higea Fitness` como rótulo visible en el
manifiesto de Android, sin cambiar applicationId ni datos ni licencias.
Si regenerás el directorio android con Flutter, repetí los comandos.

El cliente puede personalizar el nombre del estudio, su logo interior,
el color de interfaz y los modos Claro/Oscuro/Sistema.
El ícono y el rótulo del launcher se mantienen como marca del producto.

Después de probar, agregá los PNG al repositorio para que las
compilaciones de otras máquinas no queden incompletas.

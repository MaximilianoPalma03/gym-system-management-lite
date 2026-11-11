# Pantalla de inicio y contacto comercial

## Splash nativo Android

Gym Lite usa un fondo azul oscuro y un símbolo de mancuerna verde.
Se ve mientras Android inicia Flutter, antes del primer frame de la app.
En Android 12 o posterior se adapta al splash de Android.

Desde la raíz del proyecto, tras generar los archivos nativos:

```bash
dart run tool/configurar_splash.dart
flutter run
```

El script no descarga imágenes ni necesita dependencias adicionales.
Es idempotente; modifica el tema LaunchTheme y agrega tres recursos
bajo android/app/src/main/res. No toca la base SQLite ni el almacenamiento
de licencias. Puede repetirse después de regenerar android/.

Para comprobar el splash, cerrá y abrí Gym Lite desde el ícono del teléfono:
algunos dispositivos omiten la imagen al iniciarse desde depuración.
No agregamos tiempos de espera artificiales. El splash no corrige lentitud
real de menús: eso debe investigarse por separado.

## Solicitud de licencia

El botón «Enviar código al vendedor» abre WhatsApp dirigido al número
comercial configurado en lib/licensing/seller_contact.dart y prepara
un mensaje con el código de instalación. El usuario confirma el envío.
Se mantiene el botón Copiar código si no hay conexión o WhatsApp.

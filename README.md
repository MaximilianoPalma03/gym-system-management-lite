# Higea Fitness

**Higea Fitness** es una aplicación **Android offline** para estudios pequeños de pilates, yoga, gimnasios y entrenadores independientes.

## Alcance de la versión inicial

- Inicio: ingresos mensuales, clientes con cuota vigente, pendientes y próximos vencimientos.
- Clientes: alta, edición, búsqueda, activación/desactivación, teléfono y notas.
- Pagos: cobros por plan, efectivo/transferencia/tarjeta, vencimiento e historial.
- Informes: evolución mensual, medios de pago y total cobrado.
- Ajustes: nombre del estudio, planes, color y respaldo/restauración **cifrado**.

**Sin servidor, sin cuenta obligatoria y sin sincronización entre dispositivos.** Cada instalación tiene su propio archivo SQLite. Los datos se pierden si se desinstala sin guardar un respaldo externo.

## Inicio rápido

Instalá Flutter SDK y Android Studio (Android SDK), luego:

```sh
flutter create --platforms=android --project-name gym_system_management_lite .
flutter pub get
flutter run
```

> `flutter create` genera los archivos nativos de Android y `flutter pub get` las dependencias. No se incluyen binarios generados ni credenciales en el repositorio.

Para ejecutar pruebas: `flutter test`. Para obtener un APK de prueba: `flutter build apk --debug`.

### Decisiones de negocio

- Una **cuota vigente** es un cliente activo con fecha de vencimiento igual o posterior a hoy.
- **Pendiente** es cliente activo sin fecha de vencimiento o con fecha ya vencida. No representa una deuda monetaria calculada.
- Los ingresos son la **suma de cobros registrados**, no ganancias netas ni movimientos bancarios verificados.
- Un plan indica duración en días, no cantidad de asistencias. No existe módulo de control de clases.
- Una renovación anticipada empieza el día posterior al vencimiento vigente; si ya venció, comienza en la fecha del cobro.
- Los cobros guardan importe y nombre del plan como foto histórica, aunque luego se edite el plan.
- Desactivar un cliente conserva sus pagos; anular un pago lo excluye de los informes y recalcula el vencimiento desde los cobros restantes.

### Respaldo

En Ajustes se puede compartir un archivo `.gymlite` protegido con una contraseña elegida al exportar y restaurarlo posteriormente. **Guardar ese archivo fuera del celular** es responsabilidad del dueño. Restaurar reemplaza la información local tras confirmación. La contraseña no se almacena en la app.

### Estado del proyecto

MVP en desarrollo: requiere validar compilación, pruebas de interfaz en Android real y restauración con archivos reales antes de usar datos de clientes en producción.

## Privacidad

La app no envía datos por Internet; SQLite no está cifrada en reposo. Proteger el dispositivo con bloqueo de pantalla y mantener los respaldos cifrados sigue siendo indispensable. No registrar información médica sensible en notas.

## Licencia

Uso privado; sin licencia de distribución definida.

## Desarrollo y pruebas

El repositorio contiene el código Flutter, sin credenciales, binarios ni bases reales.
Los archivos de plataforma Android se generan localmente antes de compilar:

```powershell
flutter doctor
flutter create --platforms=android --project-name gym_system_management_lite .
flutter pub get
flutter analyze
flutter test
flutter run
```

Para utilizar un celular físico, habilitá Depuración USB y empezá con datos ficticios.

### Decisiones de datos

- El precio del plan es sugerido: el importe cobrado se puede ajustar antes de registrarlo.
- Los pagos anulados permanecen en el historial y no suman en informes.
- Guardar un respaldo cifrado con contraseña no cifra la base SQLite del teléfono.
- Restaurar reemplaza todo lo existente dentro de una transacción SQLite.
- No existen reservas ni control de asistencias en esta versión.

### Antes de usar datos reales

Validar compilación y funcionamiento en Android, alta y cobro, renovación anticipada,
anulación, exportación y restauración con un archivo real. Proteger el dispositivo
con bloqueo y guardar una copia externa de los respaldos.

GitHub Actions verifica análisis, pruebas y compilación debug cuando está habilitado.

## Desarrollo comercial 0.3 (rama de pruebas)

- Mensualidades **calendario** con mismo día de vencimiento y ajuste de 29/30/31.
- Planes de **duración fija** por días exactos.
- Solo anulación del último cobro válido del cliente.
- Constancias PDF tipo ticket **80 x 160 mm** para compartir por Android.
- Registro de celulares: Argentina por defecto, con Chile, Brasil y otros países.
- Licencia permanente Ed25519 por instalación, sin servidor.
- Aplicación separada `license_manager/` para generar licencias desde el teléfono.

Probá ambas aplicaciones con datos ficticios antes de distribuir un APK release.

Guías: [Reglas de cuotas](docs/REGLAS_CUOTAS.md),
[Licencias](docs/LICENCIAS.md),
[License Manager](license_manager/README.md) y
[Pruebas](docs/PRUEBAS_PARA_EL_USUARIO.md).


## Identidad Higea Fitness (rama de desarrollo)

Los recursos gráficos aprobados deben descomprimirse dentro de
`assets/branding/` antes de compilar:

```bash
flutter pub get
dart run flutter_launcher_icons
dart run tool/configurar_splash.dart
flutter analyze --no-fatal-infos
flutter test
flutter run
```

El splash nativo usa el ícono de Higea. Flutter muestra la imagen completa
durante la carga real de SQLite, sin añadir pausas artificiales.
En Ajustes puede elegirse Claro, Oscuro o Sistema, conservando el color,
el nombre y el logo de cada estudio.

No se cambia el identificador de Android ni el formato de licencia.
Para compilar en otras máquinas, agregar las imágenes aprobadas al
repositorio una vez verificadas; no contienen datos ni secretos.

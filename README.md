# Gym System Management Lite

Aplicación **Android offline** para estudios pequeños de pilates, yoga, gimnasios y entrenadores independientes.

## Alcance de la versión inicial

- Inicio: ingresos mensuales, clientes con cuota vigente, pendientes y próximos vencimientos.
- Clientes: alta, edición, búsqueda, activación/desactivación, teléfono y notas.
- Pagos: cobros por plan, efectivo/transferencia/tarjeta, vencimiento e historial.
- Informes: evolución mensual, medios de pago y total cobrado.
- Ajustes: nombre del estudio, planes, color y respaldo/restauración **cifrado**.

**Sin servidor, sin cuenta obligatoria y sin sincronización entre dispositivos.** Cada instalación tiene su propio archivo SQLite. Los datos se pierden si se desinstala sin guardar un respaldo externo.

## Inicio rápido

Instalá Flutter SDK y Android Studio (Android SDK), luego:

\`\`\`sh
flutter create --platforms=android --project-name gym_system_management_lite .
flutter pub get
flutter run
\`\`\`

> \`flutter create\` genera los archivos nativos de Android y \`flutter pub get\` las dependencias. No se incluyen binarios generados ni credenciales en el repositorio.

Para ejecutar pruebas: \`flutter test\`. Para obtener un APK de prueba: \`flutter build apk --debug\`.

### Decisiones de negocio

- Una **cuota vigente** es un cliente activo con fecha de vencimiento igual o posterior a hoy.
- **Pendiente** es cliente activo sin fecha de vencimiento o con fecha ya vencida. No representa una deuda monetaria calculada.
- Los ingresos son la **suma de cobros registrados**, no ganancias netas ni movimientos bancarios verificados.
- Un plan indica duración en días, no cantidad de asistencias. No existe módulo de control de clases.
- Una renovación anticipada empieza el día posterior al vencimiento vigente; si ya venció, comienza en la fecha del cobro.
- Los cobros guardan importe y nombre del plan como foto histórica, aunque luego se edite el plan.
- Desactivar un cliente conserva sus pagos; anular un pago lo excluye de los informes y recalcula el vencimiento desde los cobros restantes.

### Respaldo

En Ajustes se puede compartir un archivo \`.gymlite\` protegido con una contraseña elegida al exportar y restaurarlo posteriormente. **Guardar ese archivo fuera del celular** es responsabilidad del dueño. Restaurar reemplaza la información local tras confirmación. La contraseña no se almacena en la app.

### Estado del proyecto

MVP en desarrollo: requiere validar compilación, pruebas de interfaz en Android real y restauración con archivos reales antes de usar datos de clientes en producción.

## Privacidad

La app no envía datos por Internet; SQLite no está cifrada en reposo. Proteger el dispositivo con bloqueo de pantalla y mantener los respaldos cifrados sigue siendo indispensable. No registrar información médica sensible en notas.

## Licencia

Uso privado; sin licencia de distribución definida.

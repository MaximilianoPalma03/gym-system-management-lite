# Distribución y actualizaciones Android

## Antes de entregar el primer APK

1. Fijar el `applicationId` definitivo dentro del proyecto Android generado.
2. Crear **una** keystore de firma Android de producción y guardarla fuera del repo.
3. Configurar `signingConfigs.release` en `android/app/build.gradle.kts`
   y las credenciales en `android/key.properties` ignorado por Git.
4. Generar la clave maestra de licencias Ed25519 fuera del repo, y poner
   **solo la pública** en `--dart-define=GYM_LITE_PUBLIC_KEY=...`.
5. Probar un APK release en un dispositivo limpio con datos ficticios.
6. Validar exportación y restauración cifrada antes de registrar datos reales.
7. Revisar reglas de respaldo automático de Android, para que no migren
   licencias y datos sensibles por mecanismos ajenos al respaldo de la app.

## Actualizar clientes sin perder datos

- Usar exactamente el **mismo applicationId** y la **misma keystore** del APK inicial.
- Incrementar el número después de `+` en la versión de `pubspec.yaml`,
  por ejemplo de `0.2.0+2` a `0.2.1+3`.
- Conservar la misma clave pública de licencias y el esquema de validación.
- Verificar migraciones SQLite. Nunca borrar la base del usuario para actualizar.
- Compilar y distribuir la siguiente versión firmada.
- El cliente instala el APK nuevo encima del anterior; no desinstala la app.
- Primero probar el proceso completo de actualización en un teléfono de ensayo
  con clientes/pagos ficticios y un respaldo exportado.

**Una instalación hecha con `flutter run` está firmada normalmente con la clave
de debug y no se puede actualizar encima con un APK de release firmado distinto.**
Antes de desinstalar la app debug, exportar y restaurar un respaldo real y verificado.

## Personalización

El nombre, logo y paleta de colores dentro de la app se personalizan desde Ajustes.
El nombre/ícono del lanzador Android forman parte del APK compilado.
Se puede cambiar globalmente para el producto en `AndroidManifest.xml` y
con íconos `mipmap` o `flutter_launcher_icons`; hacerlo individual por estudio
multiplicaría las variantes y complicaría las actualizaciones.

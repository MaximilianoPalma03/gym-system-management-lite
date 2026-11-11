# Licencias offline con emisor desde Android

## Cómo vender una instalación

1. Instalá la app independiente **Gym Lite License Manager** en tu celular.
2. Creá **una sola clave maestra** y guardá un respaldo `.gslkey` fuera del teléfono.
3. Copiá la clave pública desde el emisor al preparar la compilación comercial:
   `flutter build apk --release --dart-define=GYM_LITE_PUBLIC_KEY=CLAVE_PUBLICA`
4. El cliente instala ese APK, toca «Enviar código al vendedor» y te lo manda.
5. Pegás el código de instalación en License Manager y tocás «Generar licencia».
6. Le enviás la clave por WhatsApp desde la propia app administradora.
7. El cliente toca «Pegar licencia» en Gym Lite; no debe tipear los 91 caracteres.
8. Una vez activada, sigue funcionando permanentemente y sin Internet.

El generador no requiere PIN o biometría; tampoco necesita Internet para firmar.
Solo para enviar la licencia por WhatsApp se requiere conexión.

### Cómo probar sin interferir con el desarrollo

Las compilaciones debug no requieren licencia por defecto. Para probar el
circuito completo, compilar la app del cliente con:

`flutter run --dart-define=REQUIRE_LICENSE=true --dart-define=GYM_LITE_PUBLIC_KEY=CLAVE_PUBLICA`

El emisor debe usar la **misma clave privada** asociada a la clave pública
que se incluyó en el APK. En release el requisito de licencia está siempre activo.

### Pérdida del celular

La clave maestra se conserva localmente en License Manager.
El respaldo `.gslkey` permite restaurarla en otro celular.
Sin ese respaldo ya no podrás emitir licencias compatibles con la edición
comercial. Si alguien obtiene ese archivo podrá firmar nuevas licencias;
guardalo fuera de GitHub y no lo envíes a compradores.

### Limitaciones

El ID es aleatorio por instalación (no un identificador de hardware).
No existe revocación remota ni protección infalible contra APKs modificados
o clonación avanzada de datos. Compartir simplemente el APK no activa
un segundo dispositivo con la misma licencia.

### Alternativa por consola

Conservamos `tool/license_admin.dart` como generador opcional en la PC.
Si ya usás License Manager, importá **su misma** `.gslkey` en la herramienta
de escritorio; no crees una clave maestra distinta.

`dart run tool/license_admin.dart issue RUTA_GSLKEY CODIGO_INSTALACION`

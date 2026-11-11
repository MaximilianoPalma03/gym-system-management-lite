# Gym Lite License Manager (Android)

Aplicación móvil exclusiva del vendedor para crear licencias permanentes
**sin Internet**. No forma parte del APK que reciben los estudios.

## Cómo iniciarla

Desde la raíz del repositorio:

```powershell
cd license_manager
flutter create --platforms=android --org ar.com.gymlite --project-name gym_lite_license_manager .
flutter pub get
flutter run
```

Si se genera una carpeta nativa, queda como proyecto Flutter independiente.

## Primera configuración

1. Abrí la app administrativa en tu celular.
2. Elegí **Crear clave maestra** una sola vez.
3. Elegí **Respaldar clave maestra** y guardá el archivo `.gslkey`
   fuera del celular. La app no tiene PIN ni biometría.
4. Copiá la **clave pública** que aparece.
5. Compilá el APK comercial de Gym Lite con
   `--dart-define=GYM_LITE_PUBLIC_KEY=CLAVE_PUBLICA`.
6. El cliente instala ese APK, copia su código de instalación y te lo envía.
7. En License Manager pegás el código, tocás **Generar licencia** y luego **Enviar**.
8. El cliente copia/pega la clave y queda activado en ese teléfono.

### Importante

- La **clave privada** queda en el almacenamiento de la app administradora.
  No se sube automáticamente al repositorio ni se manda al cliente.
- Si se borra el almacenamiento o cambiás de teléfono sin haber guardado
  el archivo `.gslkey`, perdés la capacidad de emitir claves compatibles.
- Cualquiera con una copia de la clave privada puede emitir licencias.
  Un teléfono sin Internet no significa que la clave esté protegida
  contra extracción física o malware.
- Una licencia es para una instalación, no para cada cuenta en la nube.
- No generes una segunda clave maestra para la misma edición comercial:
  las claves viejas y nuevas no serán intercambiables.

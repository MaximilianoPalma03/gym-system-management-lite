# Cómo probar la rama nueva sin perder clientes

Antes de probar, exportá un respaldo de prueba desde Ajustes y guardalo
fuera del celular. No desinstales Gym Lite.

### App Gym Lite

```bash
git fetch origin
git switch feature/licencias-comprobantes-fixes
git pull --ff-only
flutter pub get
flutter test
flutter run
```

1. Si ya tenías cobros, comprobar que sigan ahí.
2. Ajustes → Planes → crear «Mensual calendario» de 1 mes (si no existe).
3. Cliente ficticio, cobro simulado de 13/10/2026 y renovación del 11/11/2026:
   el vencimiento debe ser 13/12/2026. En nuevas instalaciones usarlo como
   primer ejemplo; si la fecha actual es distinta, utilizar la selección de fecha.
4. Ingresar pagos anticipados y comprobar que no se pierdan días.
5. Intentar anular un cobro antiguo con otro posterior: no debe ofrecerse.
   Anular el último debe restablecer el vencimiento anterior.
6. Abrir Pagos → opciones → Compartir constancia; tiene que ofrecer un **PDF**
   con formato 80 × 160 mm, no un documento A4.
7. Comprobar que Ajustes → Guardar respaldo / Restaurar no muestren errores.
8. Probar con modo avión activado.

### Gym Lite License Manager

```bash
cd license_manager
flutter create --platforms=android --org ar.com.gymlite --project-name gym_lite_license_manager .
flutter pub get
flutter run
```

1. Crear clave maestra. Guardar el archivo `.gslkey` fuera del celular.
2. Copiar clave pública.
3. Compilar Gym Lite con `--dart-define=REQUIRE_LICENSE=true` y
   `--dart-define=GYM_LITE_PUBLIC_KEY=...`.
4. Copiar código de instalación desde Gym Lite y pegarlo en License Manager.
5. Generar y compartir clave; pegar en Gym Lite.
6. Comprobar que abre normalmente al reiniciar y que una clave de otra
   instalación no funciona.

**No generar una segunda clave maestra** si ya creaste una en tu celular.

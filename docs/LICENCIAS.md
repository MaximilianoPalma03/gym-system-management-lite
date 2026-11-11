# Licencias offline por instalación (Ed25519)

**Estado:** desarrollo en rama de pruebas. No distribuir la versión release hasta
validar que las licencias, firma del APK, actualización y restauración funcionen.

## Cómo funciona

1. La instalación genera un ID aleatorio hexadecimal de 32 caracteres, guardado localmente.
2. En release se muestra la pantalla de activación hasta obtener una firma válida.
3. El desarrollador firma el ID con una clave privada Ed25519, solo en su computadora.
4. El APK verifica con una clave pública incluida al compilar, sin Internet.
5. Una vez activada la instalación, la app no vuelve a pedir la clave si conserva
   su almacenamiento local, se actualiza con la misma firma Android y se mantiene
   la misma clave pública de licencias.

Este método dificulta compartir la clave, pero **no bloquea una copia modificada
del APK ni clonaciones sofisticadas del almacenamiento de Android**. La licencia
no se revoca a distancia y cambiar de teléfono/reinstalar normalmente requiere
que el desarrollador emita una nueva clave. El respaldo de clientes no incluye
el ID de instalación ni la licencia.

## Paso 1. Generar una clave privada maestra (una sola vez)

Desde la raíz del proyecto en PowerShell o Git Bash:

```powershell
dart run tool/license_admin.dart init "C:\Users\TU_USUARIO\Documents\gym-lite-privada.json"
```

Usar una ruta *fuera del repositorio*. El archivo privado se debe copiar
de forma segura a otro medio protegido. **Si lo perdés, no podrás emitir
nuevas licencias compatibles con ese APK. Si lo filtrás, otros podrán emitirlas.**
No compartirlo por chats, correo ni GitHub.

La herramienta imprime una **clave pública** en formato base64url.
Es seguro incluir esa clave pública en compilaciones y documentación.

## Paso 2. Compilar la app con la clave pública

Para probar activación en debug:

```powershell
flutter run --dart-define=REQUIRE_LICENSE=true --dart-define=GYM_LITE_PUBLIC_KEY=PEGA_TU_CLAVE_PUBLICA
```

La compilación debug sin REQUIRE_LICENSE no exige activación para facilitar pruebas.
**Release siempre exige activación, aunque se intente configurar REQUIRE_LICENSE=false.**

Para crear un APK comercial después de configurar la firma Android:

```powershell
flutter build apk --release --dart-define=GYM_LITE_PUBLIC_KEY=PEGA_TU_CLAVE_PUBLICA
```

Si compilás release sin clave pública, aparecerá una pantalla de configuración
y ninguna licencia podrá activarse. Nunca distribuir ese APK.

## Paso 3. Emitir una licencia al cliente

El cliente te manda su ID desde la pantalla de activación. Ejecutá:

```powershell
dart run tool/license_admin.dart issue "C:\Users\TU_USUARIO\Documents\gym-lite-privada.json" CODIGO_DE_INSTALACION
```

Copiá la clave resultante `GSL1-...` y enviásela al cliente. No compartas
el archivo JSON privado. Una clave no sirve en otra instalación.

## Seguridad en Android

- El ID es de instalación, **no una identidad de hardware garantizada**.
- Android puede hacer copias automáticas del almacenamiento de aplicaciones.
  Para el APK comercial hay que revisar `android:allowBackup` y las reglas
  de extracción de datos. Evitar migrar licencia e ID a otro dispositivo.
- Proteger la firma del APK y no alterar el package ID en actualizaciones.
- No usar una clave simétrica compartida dentro del APK como sustituto
  de Ed25519: permitiría fabricar licencias a quien la extraiga.
- En caso de cambio de celular, verificar la compra y emitir otra licencia.

# Firma de Android y distribución comercial — Higea Fitness

La aplicación del cliente, la app privada License Manager y el APK no comparten ninguna clave privada.

## Antes de empezar

Conservá tu instalación debug y tus datos. El instalador comercial tendrá un ID diferente, ar.com.higeafitness.app; de esta forma podés ensayar la instalación sin borrar tu cliente de prueba. El identificador release será el mismo en todas las versiones posteriores. El debug NUEVO tendrá sufijo .dev, también separado.

La firma Android (.jks) es distinta de la clave maestra del License Manager (.gslkey).

### 1. Crear la clave Android (UNA sola vez)

Desde Git Bash, creá un directorio privado fuera del repositorio:

    mkdir -p "$HOME/HigeaKeys"

Si NO tenés una firma comercial preexistente, generala interactiva, sin contraseñas en la línea de comandos:

    keytool -genkeypair -v -keystore "$HOME/HigeaKeys/higea-release.jks" -storetype PKCS12 -keyalg RSA -keysize 3072 -validity 10000 -alias higea-release

El comando solicita contraseñas; guardalas en un gestor seguro. Si no encuentra keytool, consultá flutter doctor -v para localizar el ejecutable del JDK de Android Studio.

Resguardá una copia cifrada del JKS fuera de la computadora. Si perdés la firma y no tenés respaldo, no podrás actualizar los APK que hayan recibido los clientes. No compartas el JKS ni contraseñas por chat, GitHub o carpetas públicas.

### 2. Configuración local de Gradle

Creá el archivo android/key.properties con un editor de texto, usando tus valores privados reales:

    storePassword=CONTRASEÑA_DEL_ALMACÉN
    keyPassword=CONTRASEÑA_DE_LA_CLAVE
    keyAlias=higea-release
    storeFile=C:/Users/TU_USUARIO/HigeaKeys/higea-release.jks

Usá barras normales / en storeFile; el archivo debe existir. android/key.properties está incluido en .gitignore. Nunca lo subas al repositorio ni lo compartas.

En tu app License Manager, tocá Copiar clave pública. Pegá SOLAMENTE la clave pública en android/higea-public-key.txt, una línea y sin texto adicional. Esta clave NO es tu respaldo privado .gslkey. El archivo público local también está excluido de GitHub para no obligarte a pegarlo en la terminal en cada compilación.

Comprobá que los tres recursos gráficos (higea_icon.png, higea_icon_foreground.png y higea_splash.png) siguen en assets/branding/.

### 3. Generar un APK comercial de prueba

Desde Git Bash, en la RAÍZ de gym-system-management-lite:

    git pull --ff-only
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/build_release.ps1 -VersionName 0.9.0 -VersionCode 10

Este script valida las claves, prepara Gradle, genera íconos, ejecuta análisis y pruebas, compila release, verifica el certificado con apksigner, calcula SHA-256 y copia el resultado a:

    dist/Higea-Fitness-v0.9.0-10.apk

Si alguna comprobación falla, NO entregues el APK a terceros. No es necesario desinstalar nada. El directorio dist se mantiene fuera de GitHub.

### 4. Probar una actualización con la MISMA firma

Instalá la primera versión en el Android físico:

    adb install "dist/Higea-Fitness-v0.9.0-10.apk"

Esta instalación convive con el debug anterior y tiene base SQLite independiente. Activala con tu License Manager, creá un cliente FICTICIO, registrá un pago y cambiá el nombre/color/tema del estudio. Probá sin internet.

Generá una segunda versión desde la misma carpeta, con el mismo JKS y la misma clave pública:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/build_release.ps1 -VersionName 0.9.1 -VersionCode 11

Instalá la actualización, SIN desinstalar la primera:

    adb install -r "dist/Higea-Fitness-v0.9.1-11.apk"

Verificá que la app se abra sin pedir licencia de nuevo y que permanezcan cliente, pagos, nombre, logo y color del estudio. Comprobá que el SHA-256 del certificado firmante mostrado en ambos reportes .firma.txt sea idéntico. El SHA-256 del APK cambia entre versiones; eso es normal.

Si aparece INSTALL_FAILED_UPDATE_INCOMPATIBLE, NO desinstales para intentar arreglarlo: verificá identificador y firma. Si aparece INSTALL_FAILED_VERSION_DOWNGRADE, verificá que VersionCode aumente.

### 5. Primer lanzamiento

Cuando aprobemos ambas pruebas, generaremos un APK 1.0.0 con VersionCode mayor al usado en pruebas (por ejemplo 100), conservando el mismo JKS y el mismo applicationId.

Para nuevos APK, cambiar únicamente VersionName y VersionCode. Nunca generar otra firma privada para una actualización. Mantener también la misma clave maestra Ed25519 de License Manager.

## Entrega al comprador

Carpeta privada sugerida en Google Drive:

    Higea Fitness — Distribución/
      Versiones/
        v1.0.0/
          Higea-Fitness-v1.0.0-100.apk
          SHA256.txt
          Notas-de-version.txt
      Material para compradores/
        Instrucciones de instalación.txt
      Registro de ventas (privado)/
        Cliente, fecha, código de instalación, versión entregada

Compartí con el comprador el archivo APK específico, NO la carpeta general ni las claves. Si elegís 'Cualquier persona con el enlace', quien tenga la URL podrá descargar y reenviar el APK; la activación individual sigue siendo necesaria. Una alternativa es compartir el APK con el correo específico de cada comprador.

Para visitas presenciales, podés mostrar un QR al enlace de descarga del APK (cuando la versión esté publicada) o transmitir el archivo con Quick Share si ambos teléfonos lo permiten. El cliente instala, envía su código por WhatsApp, generás su licencia desde License Manager y finalizás con una breve demostración de clientes, cobros y respaldos.

**No desinstalar sin respaldo:** el almacenamiento local de cada comercio es independiente, y la app no sincroniza con servidores.

## Fuentes técnicas

- https://docs.flutter.dev/deployment/android
- https://developer.android.com/google/play/app-updates
- https://developer.android.com/tools/apksigner
- https://support.google.com/drive/answer/7166529?hl=es
- https://support.google.com/android/answer/9286773?hl=es

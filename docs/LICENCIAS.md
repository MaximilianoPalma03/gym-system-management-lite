# Licencias offline de Higea Fitness

Higea admite dos licencias firmadas Ed25519, vinculadas al código de una
instalación. La validación se realiza localmente y no requiere servidor.

## Tipos de licencia

- **Prueba gratuita:** 7 días completos desde la primera activación. Todas las
  funciones están disponibles durante la prueba.
- **Comercial:** permanente para esa instalación.

La prueba no empieza cuando el vendedor genera la clave, sino cuando el
comprador la introduce por primera vez. Volver a pegar la misma clave no
reinicia el plazo. La aplicación comprueba el vencimiento al abrirse, al volver
a primer plano y periódicamente mientras está abierta.

Al vencer la prueba, Higea bloquea el uso operativo, pero conserva los datos.
El usuario puede exportar un respaldo cifrado o introducir una licencia
comercial. La conversión a comercial no reinstala la app, no cambia el código
de instalación y no borra clientes, pagos ni configuraciones.

## Cómo ofrecer una prueba

1. El comprador instala el APK comercial y abre Higea.
2. En la pantalla de activación copia su código de instalación y toca
   **Enviar código al vendedor**.
3. En tu celular, abrí **Higea · Licencias** (License Manager).
4. Seleccioná **Prueba · 7 días**, pegá el código y tocá
   **Generar prueba gratuita**.
5. Enviá la clave desde la propia aplicación. El cliente la pega en Higea.
6. Higea abre todas sus funciones y muestra los días restantes de la prueba.

No es necesario que el vendedor esté conectado a Internet para generar la
clave. WhatsApp sí necesita conexión para enviarla.

## Cómo convertir la prueba en una venta

1. El comprador conserva la misma instalación y sus datos.
2. En la franja **Prueba gratuita**, toca **Activar compra**. Si la prueba ya
   venció, la pantalla de activación aparece automáticamente.
3. En License Manager seleccioná **Comercial**, pegá el mismo código y tocá
   **Generar licencia permanente**.
4. Enviá la nueva clave. El comprador la pega en Higea.
5. La app queda activada permanentemente sin reinstalar ni restaurar datos.

La misma clave maestra y la misma clave pública sirven para emitir pruebas
y licencias comerciales. No crear otra clave maestra para esta edición.

## Preparar una compilación comercial

1. En License Manager, copiá la clave pública asociada a tu clave maestra.
2. Guardala localmente en android/higea-public-key.txt.
3. Compilá con el script scripts/build_release.ps1, que lee esa clave y la
   incorpora al APK mediante GYM_LITE_PUBLIC_KEY.
4. Nunca subas la clave privada .gslkey, el archivo JKS ni sus contraseñas
   al repositorio.

## Compatibilidad

Las licencias permanentes antiguas GSL1 continúan siendo válidas. Las nuevas
emisiones usan GSL2-T para prueba y GSL2-P para licencia permanente.
La herramienta de consola antigua puede seguir generando GSL1 permanentes;
el APK nuevo las reconoce.

## Clave maestra y respaldo

La clave privada permanece en tu License Manager. Guardá un respaldo .gslkey
fuera del celular. Si perdés tanto el teléfono como ese archivo, no podrás
emitir nuevas licencias para esta clave pública. Quien obtenga la clave privada
puede emitir licencias; no la compartas con compradores.

## Límites conocidos

El sistema funciona offline y no tiene revocación remota. El código corto
identifica la instalación lógica guardada por Higea, no el hardware físico.
Si el usuario desinstala y borra los datos de la aplicación, Android puede
generar un código de instalación nuevo. El vencimiento utiliza la fecha y hora
local del dispositivo; esta versión no incorpora controles especiales contra
cambios deliberados del reloj.

Las licencias firmadas Ed25519 son más largas que el código de instalación.
El cliente no necesita escribirlas: puede pegarlas desde el portapapeles.

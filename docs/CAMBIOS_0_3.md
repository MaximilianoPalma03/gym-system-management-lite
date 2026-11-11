# Cambios 0.3 — cuotas y comprobantes

## Configuración de planes
En Ajustes > Planes hay un solo selector: **Duración del plan**.
Opciones: 1 mes, 7 días, 15 días, 30 días exactos y Otra duración.
En Otra duración se selecciona una cantidad de meses o días.
El ejemplo de vencimiento se calcula desde la fecha actual del teléfono.
Modificar un plan no altera cobros anteriores.

- 1 mes conserva el día de aniversario (13/10 → 13/11 → 13/12).
- Días exactos agrega la cantidad sin perder días al pagar anticipadamente.
- Una cuota del 31/01 vence a fines de febrero y recupera 31/03.
- Si se paga después de vencer, el nuevo aniversario parte del pago.

## Comprobantes
En Pagos > menú de un cobro:
- **Compartir comprobante** genera un PDF ticket de 80 × 160 mm y lo
  prepara para WhatsApp al celular registrado. WhatsApp puede abrir ese
  chat directamente o pedir que se seleccione, según su versión e historial.
  El dueño siempre debe confirmar el envío; la app no lo hace en automático.
- **Guardar comprobante** abre el selector de ubicación Android y escribe
  el mismo PDF en la carpeta elegida, sin requerir Internet.
- **Anular último cobro** solo aparece en el último cobro válido del cliente.
  Los comprobantes anulados quedan marcados ANULADO, no se envían como válidos.

Si falta el celular, se registra desde la ficha del cliente.
Para Argentina se admite el celular sin prefijo y se añade +549.

## Restricción técnica
Android puede compartir PDF, pero WhatsApp no ofrece una API pública que
garantice adjuntar un PDF directamente a un contacto sin mostrar su selector.
Tampoco informa si el usuario finalmente lo envió. Es necesario probarlo
en los dispositivos donde se utilice.

## Error del test generado por Flutter
Flutter create genera un archivo test/widget_test.dart con clase MyApp.
Este proyecto usa GymLiteApp y por eso el test original da error de análisis.
Hay un test/widget_test.dart nuevo y válido en Git. Si existe el generado
como archivo sin seguimiento (?? en git status), hay que borrarlo antes de
actualizar el repositorio para permitir que Git escriba el correcto.

## Comprobación
1. flutter pub get
2. flutter analyze --no-fatal-infos
3. flutter test
4. flutter run
5. Verificar ejemplo con fecha de hoy, cuota y PDF de prueba.
6. Guardar el PDF y comprobar que es legible.
7. Compartir al número argentino de prueba y observar si WhatsApp
   abre conversación o selector; confirmar envío manualmente.
8. Verificar que solo se permita anular el último pago.
9. Probar respaldo y restauración con datos ficticios.

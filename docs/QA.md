# Validación Android

Esta rama existe para validar la primera versión Flutter con GitHub Actions.
Verifica dependencias, análisis estático, pruebas SQLite y APK debug.
Los datos de prueba son ficticios y no deben usarse clientes reales.

Si la verificación falla, corregir la causa antes de considerar el MVP listo.

## Pruebas manuales pendientes

- Crear plan con precio, cliente, cobro y renovación anticipada.
- Anular pago y comprobar vencimiento e ingresos.
- Guardar respaldo `.gymlite` en archivos locales.
- Restaurarlo en otra instalación luego de confirmar la sobrescritura.
- Probar navegación y teclado en un teléfono Android.
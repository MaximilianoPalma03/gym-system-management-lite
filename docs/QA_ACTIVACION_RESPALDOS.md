# Pruebas de esta rama (hacer con información ficticia)

1. Usar `git fetch` y cambiar a `feature/licencias-comprobantes-fixes`.
2. Ejecutar `flutter pub get`, `flutter analyze`, `flutter test` y `flutter run`.
3. Exportar respaldo cifrado. Confirmar que **no aparece la pantalla roja**.
4. Compartir el respaldo por el menú de Android. Volver a la app sin errores.
5. Restaurar desde ese archivo y confirmar que los clientes y cobros vuelven.
6. Crear un cliente que vence en tres días; registrar una cuota de 30 días;
   comprobar que queden 33 días (según convención de fechas).
7. Registrar tres pagos anticipados y anular el primero. Confirmar que se
   recalculan los períodos posteriores y los informes excluyen el anulado.
8. Abrir un cobro, elegir Compartir constancia; revisar datos y vencimiento.
9. Guardar número como `+54 9 ...` y abrir envío por WhatsApp.
10. Configurar nombre, colores y un logo PNG/JPG de menos de 350 KB.
11. Generar clave privada **en tu PC, fuera del repositorio** y compilar
    debug con REQUIRE_LICENSE=true y GYM_LITE_PUBLIC_KEY.
12. Comprobar: una licencia correcta activa; una incorrecta se rechaza;
    la licencia de un dispositivo NO activa en otro; al reiniciar queda activo.

No preparar APK release comercial hasta probar la firma Android y actualizar
una instalación existente sin perder datos.

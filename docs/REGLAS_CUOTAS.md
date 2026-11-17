# Reglas de las cuotas (2026-11)

## Dos modalidades

1. **Mes(es) calendario:** vence siempre el mismo día del mes. Ejemplo:
   primer pago 13/10/2026 -> vence 13/11/2026; si renueva el 11/11/2026,
   el vencimiento pasa al **13/12/2026** (32 días desde la renovación).
2. **Días fijos:** cantidad exacta de días (7, 15, 30, etc.). Si renueva antes
   de vencer, los días nuevos se agregan a continuación del período vigente.

### 29, 30 y 31

El sistema guarda el día de aniversario. Una cuota mensual iniciada el
31/01/2027 vence el 28/02/2027, y al renovar vuelve al 31/03/2027.
No cambia permanentemente al 28.

### Pago atrasado

Si el cliente ya tiene la cuota vencida al pagar, el nuevo ciclo comienza
en la **fecha del nuevo cobro** y se establece ese día como nuevo aniversario.
Es una regla de producto que se debe comunicar a los estudios.

### Anulación

- Solo se puede anular el **último cobro no anulado** del cliente.
- La anulación deja evidencia histórica, no suma ingresos y restaura el
  vencimiento registrado por el cobro anterior.
- No se anulan cobros previos si existen cobros posteriores válidos.

### Migraciones

El esquema SQLite v3 agrega los ciclos calendario a los planes y guarda el
día de aniversario por cliente y pago. Las cuotas históricas permanecen como
planes de días fijos; **no se convierten automáticamente**. Las instalaciones
existentes reciben un plan nuevo llamado «Mensual calendario» y las nuevas
instalaciones lo traen como predeterminado.

### Respaldo

Los nuevos archivos de respaldo usan formato 2. Los respaldos antiguos del
formato 1 se pueden restaurar con las reglas de días fijos existentes.

### Clientes inactivos por falta de pago

- Por defecto, un cliente pasa a **Inactivo** cuando supera **30 días
  adicionales desde el vencimiento**. Hasta el día 30 inclusive figura
  **Pendiente**; desde el día 31 figura **Inactivo**.
- El plazo se puede ajustar entre 1 y 365 días desde **Ajustes**.
- Es un estado **calculado**, no modifica el campo `active`, no elimina
  clientes ni pagos, y se revierte automáticamente cuando el cliente renueva.
- Sin vencimiento previo, Higea no puede saber si hubo inasistencia: el
  cliente permanece Pendiente hasta que se registre un pago.
- La desactivación manual prevalece y requiere reactivación manual antes
  de registrar un cobro.
- En Clientes, **Activos** incluye vigentes y pendientes; **Ver inactivos**
  muestra exclusivamente inactivos; **Incluir inactivos** muestra todos.
- En el resumen, la cuenta de **Pendientes** deja de incluir a quienes
  superaron el plazo y ahora son inactivos.

import 'package:sqflite/sqflite.dart';
import '../core/formatters.dart';
import 'app_database.dart';
import 'models.dart';

class GymRepository {
  const GymRepository(this.storage);
  final AppDatabase storage;

  Future<List<StudioClient>> clients() async {
    final db = await storage.database;
    return (await db.query('clients', orderBy: 'active DESC, name COLLATE NOCASE ASC'))
        .map(StudioClient.fromRow).toList();
  }

  Future<List<StudioPlan>> plans() async {
    final db = await storage.database;
    return (await db.query('plans', orderBy: 'active DESC, name COLLATE NOCASE ASC'))
        .map(StudioPlan.fromRow).toList();
  }

  Future<List<StudioPayment>> payments() async {
    final db = await storage.database;
    final rows = await db.rawQuery('''
      SELECT p.*, c.name AS client_name FROM payments p
      INNER JOIN clients c ON c.id = p.client_id
      ORDER BY p.paid_at DESC, p.id DESC''');
    return rows.map(StudioPayment.fromRow).toList();
  }

  Future<Map<String, String>> settings() async {
    final db = await storage.database;
    return {for (final row in await db.query('settings')) row['key'] as String: row['value'] as String};
  }

  Future<void> saveSetting(String key, String value) async {
    if (!['studio_name', 'color_index'].contains(key)) throw ArgumentError('Configuración inválida');
    final db = await storage.database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveClient({int? id, required String name, String phone = '',
    String notes = '', bool active = true}) async {
    final normalized = name.trim();
    if (normalized.length < 2 || normalized.length > 100) {
      throw ArgumentError('Ingresá un nombre de 2 a 100 caracteres.');
    }
    if (phone.length > 40 || notes.length > 500) throw ArgumentError('Teléfono o notas demasiado largos.');
    final db = await storage.database;
    final current = DateTime.now().toUtc().toIso8601String();
    if (id == null) {
      await db.insert('clients', {
        'name': normalized, 'phone': phone.trim(), 'notes': notes.trim(),
        'active': active ? 1 : 0, 'created_at': current, 'updated_at': current,
      });
    } else {
      final updated = await db.update('clients', {
        'name': normalized, 'phone': phone.trim(), 'notes': notes.trim(),
        'active': active ? 1 : 0, 'updated_at': current,
      }, where: 'id = ?', whereArgs: [id]);
      if (updated != 1) throw StateError('No se encontró el cliente.');
    }
  }

  Future<void> setClientActive(int id, bool value) async {
    final db = await storage.database;
    await db.update('clients', {
      'active': value ? 1 : 0, 'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> savePlan({int? id, required String name, required int durationDays,
    required int priceCents, bool active = true}) async {
    if (name.trim().isEmpty || name.length > 70) throw ArgumentError('Nombre de plan inválido.');
    if (durationDays < 1 || durationDays > 3650 || priceCents < 0) {
      throw ArgumentError('Duración o precio fuera de rango.');
    }
    final values = {
      'name': name.trim(), 'duration_days': durationDays,
      'price_cents': priceCents, 'active': active ? 1 : 0,
    };
    final db = await storage.database;
    if (id == null) {
      await db.insert('plans', values);
    } else {
      await db.update('plans', values, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> recordPayment({required int clientId, required int planId,
    required int amountCents, required String method, required DateTime paidAt,
    String notes = ''}) async {
    if (amountCents <= 0) throw ArgumentError('El importe debe ser mayor a cero.');
    if (!['Efectivo', 'Transferencia', 'Tarjeta', 'Otro'].contains(method)) {
      throw ArgumentError('Medio de pago inválido.');
    }
    if (notes.length > 500) throw ArgumentError('Notas demasiado largas.');
    final db = await storage.database;
    await db.transaction((tx) async {
      final clientRows = await tx.query('clients', where: 'id = ?', whereArgs: [clientId]);
      final planRows = await tx.query('plans', where: 'id = ?', whereArgs: [planId]);
      if (clientRows.isEmpty || planRows.isEmpty) throw StateError('Cliente o plan inexistente.');
      final client = clientRows.first;
      final plan = planRows.first;
      if (client['active'] != 1) throw StateError('El cliente está inactivo.');
      if (plan['active'] != 1) throw StateError('El plan está desactivado.');
      final currentDue = nullableDate(client['due_date']);
      final paymentDay = day(paidAt);
      final periodStart = currentDue != null && compareDays(currentDue, paymentDay) >= 0
          ? day(currentDue).add(const Duration(days: 1)) : paymentDay;
      final periodEnd = periodStart.add(Duration(days: (plan['duration_days'] as int) - 1));
      await tx.insert('payments', {
        'client_id': clientId, 'plan_id': planId,
        'plan_name': plan['name'], 'amount_cents': amountCents,
        'method': method, 'paid_at': dateKey(paymentDay),
        'period_start': dateKey(periodStart), 'period_end': dateKey(periodEnd),
        'notes': notes.trim(), 'voided': 0, 'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      await tx.update('clients', {
        'plan_id': planId, 'due_date': dateKey(periodEnd),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, where: 'id = ?', whereArgs: [clientId]);
    });
  }

  Future<void> voidPayment(int paymentId) async {
    final db = await storage.database;
    await db.transaction((tx) async {
      final matches = await tx.query('payments', where: 'id = ? AND voided = 0', whereArgs: [paymentId]);
      if (matches.isEmpty) throw StateError('Pago no encontrado o ya anulado.');
      final clientId = matches.first['client_id'] as int;
      await tx.update('payments', {'voided': 1}, where: 'id = ?', whereArgs: [paymentId]);
      final remaining = await tx.query('payments',
        columns: ['plan_id', 'period_end'], where: 'client_id = ? AND voided = 0',
        whereArgs: [clientId], orderBy: 'period_end DESC, id DESC', limit: 1);
      await tx.update('clients', {
        'due_date': remaining.isEmpty ? null : remaining.first['period_end'],
        'plan_id': remaining.isEmpty ? null : remaining.first['plan_id'],
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, where: 'id = ?', whereArgs: [clientId]);
    });
  }

  Future<Map<String, dynamic>> exportData() async {
    final db = await storage.database;
    return {
      'format': 'gym-lite-data',
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'plans': await db.query('plans', orderBy: 'id'),
      'clients': await db.query('clients', orderBy: 'id'),
      'payments': await db.query('payments', orderBy: 'id'),
      'settings': await db.query('settings', orderBy: 'key'),
    };
  }

  Future<void> restoreData(Map<String, dynamic> data) async {
    if (data['format'] != 'gym-lite-data' || data['version'] != 1) {
      throw const FormatException('Versión de respaldo no compatible.');
    }
    for (final key in ['plans', 'clients', 'payments', 'settings']) {
      if (data[key] is! List) throw const FormatException('Respaldo incompleto.');
      if ((data[key] as List).length > 200000) throw const FormatException('Respaldo demasiado grande.');
    }
    // Whitelist de columnas para evitar restaurar esquemas o datos arbitrarios.
    const columns = {
      'plans': ['id', 'name', 'duration_days', 'price_cents', 'active'],
      'clients': ['id', 'name', 'phone', 'notes', 'active', 'plan_id', 'due_date', 'created_at', 'updated_at'],
      'payments': ['id', 'client_id', 'plan_id', 'plan_name', 'amount_cents', 'method',
        'paid_at', 'period_start', 'period_end', 'notes', 'voided', 'created_at'],
      'settings': ['key', 'value'],
    };
    final db = await storage.database;
    await db.transaction((tx) async {
      for (final table in ['payments', 'clients', 'plans', 'settings']) {
        await tx.delete(table);
      }
      for (final table in ['plans', 'clients', 'payments', 'settings']) {
        for (final item in data[table] as List) {
          if (item is! Map) throw const FormatException('Registro inválido.');
          final row = <String, Object?>{};
          for (final col in columns[table]!) {
            if (!item.containsKey(col)) throw const FormatException('Faltan columnas en el respaldo.');
            final value = item[col];
            if (value != null && value is! String && value is! int) {
              throw const FormatException('Tipo de dato inválido.');
            }
            row[col] = value;
          }
          await tx.insert(table, row);
        }
      }
    });
  }
}

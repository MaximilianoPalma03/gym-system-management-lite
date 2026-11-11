import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gym_system_management_lite/data/app_database.dart';
import 'package:gym_system_management_lite/data/gym_repository.dart';
import 'package:gym_system_management_lite/services/backup_service.dart';

void main() {
  late AppDatabase storage;
  late GymRepository repo;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    storage = AppDatabase(testPath: inMemoryDatabasePath);
    repo = GymRepository(storage);
    await storage.database;
  });
  tearDown(() async => storage.close());

  test('La instalación inicial tiene dos planes y configuración local', () async {
    expect((await repo.plans()).length, 2);
    expect((await repo.settings())['studio_name'], 'Mi estudio');
    expect(await repo.clients(), isEmpty);
    expect(await repo.payments(), isEmpty);
  });

  test('Renovar anticipadamente conserva la vigencia y permite anular', () async {
    await repo.saveClient(name: 'Ana Test');
    final client = (await repo.clients()).single;
    await repo.savePlan(name: 'Mensual pago', durationDays: 30, priceCents: 2500000);
    final plan = (await repo.plans()).firstWhere((p) => p.name == 'Mensual pago');
    await repo.recordPayment(clientId: client.id, planId: plan.id,
      amountCents: 2500000, method: 'Efectivo', paidAt: DateTime(2026, 11, 10));
    expect((await repo.clients()).single.dueDate!.toIso8601String().substring(0, 10),
      '2026-12-09');
    await repo.recordPayment(clientId: client.id, planId: plan.id,
      amountCents: 2500000, method: 'Tarjeta', paidAt: DateTime(2026, 11, 20));
    expect((await repo.clients()).single.dueDate!.toIso8601String().substring(0, 10),
      '2027-01-08');
    final payments = await repo.payments();
    expect(payments.length, 2);
    expect(payments.first.periodStart.toIso8601String().substring(0, 10), '2026-12-10');
    await repo.voidPayment(payments.first.id);
    expect((await repo.clients()).single.dueDate!.toIso8601String().substring(0, 10),
      '2026-12-09');
    expect((await repo.payments()).where((p) => p.voided).length, 1);
  });

  test('Solo se permite anular el último cobro del cliente', () async {
    await repo.saveClient(name: 'Renovación consecutiva');
    final c = (await repo.clients()).single;
    await repo.savePlan(name: '30 días', durationDays: 30, priceCents: 100000);
    final p = (await repo.plans()).firstWhere((plan) => plan.name == '30 días');
    for (final date in [DateTime(2026, 11, 10), DateTime(2026, 11, 20)]) {
      await repo.recordPayment(clientId: c.id, planId: p.id,
        amountCents: 100000, method: 'Efectivo', paidAt: date);
    }
    final payments = await repo.payments();
    await expectLater(repo.voidPayment(payments.last.id), throwsStateError);
    expect((await repo.payments()).where((pay) => pay.voided), isEmpty);
    await repo.voidPayment(payments.first.id);
    expect((await repo.clients()).single.dueDate, DateTime(2026, 12, 9));
  });

  test('Mensual calendario conserva el día 13, incluso con cobro anticipado', () async {
    await repo.saveClient(name: 'Cliente del día 13');
    final client = (await repo.clients()).single;
    final plan = (await repo.plans()).firstWhere((p) => p.cycleKind == 'months');
    await repo.recordPayment(clientId: client.id, planId: plan.id,
      amountCents: 3000000, method: 'Efectivo',
      paidAt: DateTime(2026, 10, 13));
    expect((await repo.clients()).single.dueDate, DateTime(2026, 11, 13));
    await repo.recordPayment(clientId: client.id, planId: plan.id,
      amountCents: 3000000, method: 'Transferencia',
      paidAt: DateTime(2026, 11, 11));
    expect((await repo.clients()).single.dueDate, DateTime(2026, 12, 13));
    expect((await repo.clients()).single.billingAnchorDay, 13);

    final lastPayment = (await repo.payments()).first;
    await repo.voidPayment(lastPayment.id);
    expect((await repo.clients()).single.dueDate, DateTime(2026, 11, 13));
    expect((await repo.clients()).single.billingAnchorDay, 13);
  });

  test('Un error en el cobro no modifica la base de datos', () async {
    await repo.saveClient(name: 'Cliente prueba');
    final customer = (await repo.clients()).single;
    final plan = (await repo.plans()).first;
    await expectLater(
      repo.recordPayment(clientId: customer.id, planId: plan.id,
        amountCents: 0, method: 'Efectivo', paidAt: DateTime(2026, 11, 10)),
      throwsArgumentError,
    );
    expect(await repo.payments(), isEmpty);
    expect((await repo.clients()).single.dueDate, isNull);
  });

  test('Respaldo cifrado se restaura y rechaza otra contraseña', () async {
    await repo.saveClient(name: 'Cliente de respaldo');
    final backup = BackupService(repo);
    final bytes = await backup.exportEncrypted('contraseña-muy-segura');
    expect(utf8.decode(bytes), isNot(contains('Cliente de respaldo')));
    await expectLater(backup.decrypt(bytes, 'incorrecta'), throwsA(anything));
    final content = await backup.decrypt(bytes, 'contraseña-muy-segura');
    await repo.saveClient(name: 'Otro cliente');
    await repo.restoreData(content);
    expect((await repo.clients()).length, 1);
    expect((await repo.clients()).single.name, 'Cliente de respaldo');
  });

  test('Una restauración inválida es transaccional', () async {
    await repo.saveClient(name: 'Dato original');
    final data = await repo.exportData();
    // Las listas devueltas por sqflite son de solo lectura. Creamos una copia
    // modificable para simular un respaldo con un registro incompleto.
    data['clients'] = [
      ...(data['clients'] as List),
      {'id': 500, 'name': 'Registro incompleto'},
    ];
    await expectLater(repo.restoreData(data), throwsA(isA<Exception>()));
    expect((await repo.clients()).single.name, 'Dato original');
  });
}

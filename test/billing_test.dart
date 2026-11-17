import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system_management_lite/core/billing.dart';

void main() {
  test('13 de octubre vence 13 de noviembre y renovación el 11 conserva 32 días', () {
    final first = calculateBillingPeriod(
      paidAt: DateTime(2026, 10, 13), cycleKind: 'months',
      durationDays: 30, cycleMonths: 1);
    expect(first.end, DateTime(2026, 11, 13));
    expect(first.anchorDay, 13);
    final renewal = calculateBillingPeriod(
      paidAt: DateTime(2026, 11, 11), cycleKind: 'months',
      durationDays: 30, cycleMonths: 1,
      previousDue: first.end, previousAnchorDay: first.anchorDay);
    expect(renewal.end, DateTime(2026, 12, 13));
    expect(renewal.end.difference(DateTime(2026, 11, 11)).inDays, 32);
    expect(renewal.anchorDay, 13);
  });

  test('Día 31 recuperado después de febrero', () {
    final january = calculateBillingPeriod(
      paidAt: DateTime(2027, 1, 31), cycleKind: 'months',
      durationDays: 30, cycleMonths: 1);
    expect(january.end, DateTime(2027, 2, 28));
    final february = calculateBillingPeriod(
      paidAt: DateTime(2027, 2, 27), cycleKind: 'months',
      durationDays: 30, cycleMonths: 1,
      previousDue: january.end, previousAnchorDay: january.anchorDay);
    expect(february.end, DateTime(2027, 3, 31));
  });

  test('El atraso reinicia el calendario desde el nuevo pago', () {
    final newPeriod = calculateBillingPeriod(
      paidAt: DateTime(2026, 11, 17), cycleKind: 'months',
      durationDays: 30, previousDue: DateTime(2026, 11, 13),
      previousAnchorDay: 13);
    expect(newPeriod.end, DateTime(2026, 12, 17));
    expect(newPeriod.anchorDay, 17);
  });

  test('La duración fija conserva exactamente los días restantes', () {
    final next = calculateBillingPeriod(
      paidAt: DateTime(2026, 11, 11), cycleKind: 'days',
      durationDays: 30, previousDue: DateTime(2026, 11, 13));
    expect(next.start, DateTime(2026, 11, 14));
    expect(next.end, DateTime(2026, 12, 13));
    expect(next.anchorDay, null);
  });
}

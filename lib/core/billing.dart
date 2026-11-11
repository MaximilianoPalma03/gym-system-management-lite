import 'dart:math' as math;
import 'formatters.dart';

/// 'days' significa X días exactos; 'months' conserva el día calendario
/// original aun si el mes intermedio carece del día 29, 30 o 31.
class BillingPeriod {
  const BillingPeriod({required this.start, required this.end, this.anchorDay});
  final DateTime start;
  final DateTime end;
  final int? anchorDay;
}

DateTime anchoredMonth(DateTime reference, int months, int anchorDay) {
  if (months <= 0 || months > 120 || anchorDay < 1 || anchorDay > 31) {
    throw ArgumentError('Meses o día de vencimiento inválidos.');
  }
  final first = DateTime(reference.year, reference.month + months, 1);
  final days = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, math.min(days, anchorDay));
}

BillingPeriod calculateBillingPeriod({
  required DateTime paidAt,
  required String cycleKind,
  required int durationDays,
  int cycleMonths = 1,
  DateTime? previousDue,
  int? previousAnchorDay,
}) {
  final paid = day(paidAt);
  final due = previousDue == null ? null : day(previousDue);
  final stillValid = due != null && compareDays(due, paid) >= 0;
  if (cycleKind == 'months') {
    if (cycleMonths < 1 || cycleMonths > 120) throw ArgumentError('Cantidad de meses inválida');
    final anchor = stillValid ? (previousAnchorDay ?? due!.day) : paid.day;
    final start = stillValid ? due!.add(const Duration(days: 1)) : paid;
    final end = anchoredMonth(stillValid ? due! : paid, cycleMonths, anchor);
    return BillingPeriod(start: start, end: end, anchorDay: anchor);
  }
  if (cycleKind != 'days') throw ArgumentError('Tipo de plan desconocido');
  if (durationDays < 1 || durationDays > 3650) throw ArgumentError('Duración inválida');
  final start = stillValid ? due!.add(const Duration(days: 1)) : paid;
  return BillingPeriod(
    start: start,
    end: start.add(Duration(days: durationDays - 1)),
  );
}

import '../core/formatters.dart';

class StudioClient {
  const StudioClient({required this.id, required this.name, this.phone = '', this.notes = '',
    required this.active, this.planId, this.dueDate, this.billingAnchorDay, required this.createdAt});
  final int id;
  final String name;
  final String phone;
  final String notes;
  final bool active;
  final int? planId;
  final DateTime? dueDate;
  final int? billingAnchorDay;
  final String createdAt;
  factory StudioClient.fromRow(Map<String, Object?> r) => StudioClient(
    id: r['id'] as int, name: r['name'] as String, phone: r['phone'] as String? ?? '',
    notes: r['notes'] as String? ?? '', active: (r['active'] as int) == 1,
    planId: r['plan_id'] as int?, dueDate: nullableDate(r['due_date']),
    billingAnchorDay: r['billing_anchor_day'] as int?,
    createdAt: r['created_at'] as String,
  );
}

class StudioPlan {
  const StudioPlan({required this.id, required this.name, required this.durationDays,
    required this.priceCents, required this.active,
    this.cycleKind = 'days', this.cycleMonths = 1});
  final int id;
  final String name;
  final int durationDays;
  final String cycleKind;
  final int cycleMonths;
  bool get isCalendarMonthly => cycleKind == 'months';
  final int priceCents;
  final bool active;
  factory StudioPlan.fromRow(Map<String, Object?> r) => StudioPlan(
    id: r['id'] as int, name: r['name'] as String, durationDays: r['duration_days'] as int,
    priceCents: r['price_cents'] as int, active: (r['active'] as int) == 1,
    cycleKind: r['cycle_kind'] as String? ?? 'days', cycleMonths: r['cycle_months'] as int? ?? 1,
  );
}

class StudioPayment {
  const StudioPayment({required this.id, required this.clientId, required this.planId,
    required this.planName, required this.clientName, required this.amountCents,
    required this.method, required this.paidAt, required this.periodStart,
    required this.periodEnd, required this.notes, required this.voided});
  final int id;
  final int clientId;
  final int planId;
  final String planName;
  final String clientName;
  final int amountCents;
  final String method;
  final DateTime paidAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String notes;
  final bool voided;
  factory StudioPayment.fromRow(Map<String, Object?> r) => StudioPayment(
    id: r['id'] as int, clientId: r['client_id'] as int, planId: r['plan_id'] as int,
    planName: r['plan_name'] as String,
    clientName: r['client_name'] as String? ?? '',
    amountCents: r['amount_cents'] as int, method: r['method'] as String,
    paidAt: parseDate(r['paid_at'] as String),
    periodStart: parseDate(r['period_start'] as String),
    periodEnd: parseDate(r['period_end'] as String),
    notes: r['notes'] as String? ?? '', voided: (r['voided'] as int) == 1,
  );
}

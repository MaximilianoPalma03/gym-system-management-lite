import 'package:intl/intl.dart';

final _arsFormat = NumberFormat.currency(locale: 'es_AR', symbol: r'$ ', decimalDigits: 0);
final _dateFormat = DateFormat('dd/MM/yyyy', 'es_AR');

String dateKey(DateTime value) {
  final date = DateTime(value.year, value.month, value.day);
  return DateFormat('yyyy-MM-dd').format(date);
}
DateTime parseDate(String value) => DateTime.parse(value);
String formatDate(DateTime? value) => value == null ? 'Sin fecha' : _dateFormat.format(value);
String formatMoney(int cents) => _arsFormat.format(cents / 100);

/// Admite pesos argentinos: 12000, 12.000, 12000,50, 12.000,50 y 12000.50.
/// Evita interpretar 1500.50 como 150050 pesos.
int? parseMoney(String raw) {
  final value = raw.trim().replaceAll(' ', '').replaceAll(r'$', '');
  if (value.isEmpty) return null;
  String normalized;
  if (value.contains(',')) {
    if (!RegExp(r'^\d+(,\d{1,2})?$|^\d{1,3}(\.\d{3})+(,\d{1,2})?$').hasMatch(value)) {
      return null;
    }
    normalized = value.replaceAll('.', '').replaceAll(',', '.');
  } else if (value.contains('.')) {
    if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(value)) {
      normalized = value.replaceAll('.', '');
    } else if (RegExp(r'^\d+\.\d{1,2}$').hasMatch(value)) {
      normalized = value;
    } else {
      return null;
    }
  } else {
    if (!RegExp(r'^\d+$').hasMatch(value)) return null;
    normalized = value;
  }
  final amount = double.tryParse(normalized);
  if (amount == null || !amount.isFinite || amount < 0 || amount > 100000000000) return null;
  return (amount * 100).round();
}
DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
int compareDays(DateTime a, DateTime b) => day(a).compareTo(day(b));
DateTime? nullableDate(Object? value) => value == null ? null : DateTime.tryParse(value as String);

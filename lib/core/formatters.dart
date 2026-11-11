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
int? parseMoney(String raw) {
  final cleaned = raw.trim().replaceAll(' ', '').replaceAll(r'$', '');
  if (cleaned.isEmpty) return null;
  // ARS: '12.500,50' o '12500'; no usar coma para miles.
  final normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
  final number = double.tryParse(normalized);
  if (number == null || !number.isFinite || number < 0 || number > 100000000000) return null;
  return (number * 100).round();
}
DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
int compareDays(DateTime a, DateTime b) => day(a).compareTo(day(b));
DateTime? nullableDate(Object? value) => value == null ? null : DateTime.tryParse(value as String);

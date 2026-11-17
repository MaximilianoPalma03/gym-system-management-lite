import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system_management_lite/core/formatters.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('es_AR'));

  test('Importes argentinos, puntos y comas', () {
    expect(parseMoney('12500'), 1250000);
    expect(parseMoney('12.500'), 1250000);
    expect(parseMoney('12.500,50'), 1250050);
    expect(parseMoney('12500.50'), 1250050);
    expect(parseMoney('1.234'), 123400);
    expect(parseMoney('12,5'), 1250);
    expect(parseMoney(''), null);
    expect(parseMoney('-10'), null);
    expect(parseMoney('12.3.4'), null);
  });
  test('La comparación de fechas ignora las horas', () {
    expect(compareDays(DateTime(2026, 11, 10, 3), DateTime(2026, 11, 10, 22)), 0);
    expect(dateKey(DateTime(2026, 11, 10)), '2026-11-10');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system_management_lite/core/phones.dart';

void main() {
  test('Argentina es el país predeterminado y se agrega 549', () {
    expect(normalizePhone('351 1234567', 'AR'), '+5493511234567');
    expect(normalizePhone('+54 9 351 1234567', 'AR'), '+5493511234567');
  });
  test('Chile y Brasil aceptan sus códigos', () {
    expect(normalizePhone('9 1234 5678', 'CL'), '+56912345678');
    expect(normalizePhone('11 91234-5678', 'BR'), '+5511912345678');
  });
  test('Rechaza datos nacionales incompletos', () {
    expect(() => normalizePhone('123', 'AR'), throwsFormatException);
    expect(() => normalizePhone('3511234567', 'OTHER'), throwsFormatException);
    expect(normalizePhone('', 'AR'), '');
  });
}

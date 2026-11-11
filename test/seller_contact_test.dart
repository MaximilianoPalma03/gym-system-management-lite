import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system_management_lite/licensing/seller_contact.dart';

void main() {
  test('La solicitud se dirige al WhatsApp comercial y contiene el código', () {
    final url = SellerContact.activationRequest('A4Y3B7K2');
    expect(url.scheme, 'https');
    expect(url.host, 'wa.me');
    expect(url.path, '/5493544432383');
    expect(url.queryParameters['text'], contains('A4Y3-B7K2'));
    expect(url.queryParameters['text'], contains('Higea Fitness'));
  });
}

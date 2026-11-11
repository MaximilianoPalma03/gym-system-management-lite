import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system_management_lite/licensing/seller_contact.dart';

void main() {
  test('La solicitud de prueba se dirige al WhatsApp comercial y contiene el código', () {
    final url = SellerContact.activationRequest('A4Y3B7K2');
    expect(url.scheme, 'https');
    expect(url.host, 'wa.me');
    expect(url.path, '/5493544432383');
    expect(url.queryParameters['text'], contains('A4Y3-B7K2'));
    expect(url.queryParameters['text'], contains('Higea Fitness'));
    expect(url.queryParameters['text'], contains('prueba gratuita de 7 días'));
  });

  test('Una prueba vencida solicita la licencia comercial', () {
    final url = SellerContact.activationRequest('A4Y3B7K2', trialExpired: true);
    expect(url.queryParameters['text'], contains('licencia comercial'));
    expect(url.queryParameters['text'], contains('A4Y3-B7K2'));
  });
}

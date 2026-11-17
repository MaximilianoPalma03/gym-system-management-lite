import 'dart:convert';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system_management_lite/data/models.dart';
import 'package:gym_system_management_lite/services/receipt_service.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('es_AR'));

  test('Constancia de pago incluye los datos y no es factura', () {
    final p = StudioPayment(
      id: 14, clientId: 1, planId: 3,
      planName: '30 días', clientName: 'María Pérez',
      amountCents: 2000000, method: 'Efectivo',
      paidAt: DateTime(2026, 11, 11), periodStart: DateTime(2026, 11, 14),
      periodEnd: DateTime(2026, 12, 13), notes: '', voided: false,
    );
    final text = ReceiptService.content('Mi estudio', p);
    expect(text, contains('María Pérez'));
    expect(text, contains('Vencimiento: 13/12/2026'));
    expect(text, contains('No es una factura'));
  });
  test('Genera un PDF pequeño válido sin Internet', () async {
    final payment = StudioPayment(
      id: 44, clientId: 1, planId: 1,
      planName: 'Mensual calendario', clientName: 'Ana Díaz',
      amountCents: 3000000, method: 'Transferencia',
      paidAt: DateTime(2026, 11, 11),
      periodStart: DateTime(2026, 11, 14),
      periodEnd: DateTime(2026, 12, 13),
      notes: '', voided: false,
    );
    final bytes = await ReceiptService.buildTicketPdf(
      studioName: 'Estudio Pilates', payment: payment);
    expect(utf8.decode(bytes.take(4).toList()), '%PDF');
    expect(bytes.length, greaterThan(500));
  });

  test('Solo envía WhatsApp directamente a números con prefijo internacional', () {
    expect(ReceiptService.whatsappPhone('+54 9 351 1234567'), '5493511234567');
    expect(ReceiptService.whatsappPhone('3511234567'), null);
  });
}

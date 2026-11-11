import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/formatters.dart';
import '../data/models.dart';
import '../state/gym_store.dart';
import '../ui/widgets/common.dart';

class ReceiptService {
  const ReceiptService._();

  static String content(String studio, StudioPayment payment) => [
    studio,
    'CONSTANCIA DE PAGO N.º ' + payment.id.toString(),
    '',
    'Cliente: ' + payment.clientName,
    'Plan: ' + payment.planName,
    'Cobrado: ' + formatMoney(payment.amountCents),
    'Medio: ' + payment.method,
    'Fecha de cobro: ' + formatDate(payment.paidAt),
    'Período: ' + formatDate(payment.periodStart) + ' al ' + formatDate(payment.periodEnd),
    'Vencimiento: ' + formatDate(payment.periodEnd),
    if (payment.voided) 'ATENCIÓN: ESTE PAGO FUE ANULADO',
    '',
    'Constancia interna del estudio. No es una factura ni comprobante fiscal.',
  ].join('\n');

  static Future<void> share(BuildContext context, GymStore store, StudioPayment payment) async {
    try {
      await SharePlus.instance.share(ShareParams(
        text: content(store.studioName, payment),
        title: 'Constancia de pago',
      ));
    } catch (e) {
      if (context.mounted) notice(context, 'No se pudo compartir la constancia: $e');
    }
  }

  /// Solo números ya almacenados en formato internacional E.164 (+549...).
  /// No adivinamos códigos de área ni añadimos prefijos automáticamente.
  static String? whatsappPhone(String rawPhone) {
    final trimmed = rawPhone.trim();
    if (!trimmed.startsWith('+')) return null;
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 15) return null;
    return digits;
  }

  static Future<void> whatsapp(BuildContext context, GymStore store, StudioPayment payment) async {
    final phone = store.clientById(payment.clientId)?.phone ?? '';
    final digits = whatsappPhone(phone);
    if (digits == null) {
      notice(context, 'Para enviar directo, guardá el teléfono con código internacional (+549...). '
        'Podés usar Compartir constancia para elegir el contacto manualmente.');
      return;
    }
    final uri = Uri.https('wa.me', '/$digits', {
      'text': content(store.studioName, payment),
    });
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        notice(context, 'No se pudo abrir WhatsApp. Usá Compartir constancia.');
      }
    } catch (e) {
      if (context.mounted) notice(context, 'No se pudo abrir WhatsApp: $e');
    }
  }
}

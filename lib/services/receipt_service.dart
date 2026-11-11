import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:whatsapp_share_plus/whatsapp_share_plus.dart';
import 'package:flutter/material.dart';
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

  /// Ticket PDF de 80 x 160 mm. Se genera totalmente sin Internet.
  /// No es documento fiscal ni comprobante de ARCA.
  static Future<Uint8List> buildTicketPdf({
    required String studioName,
    required StudioPayment payment,
    String? logoBase64,
  }) async {
    final pdf = pw.Document(
      title: 'Constancia de pago ' + payment.id.toString(),
      author: studioName,
    );
    pw.MemoryImage? logo;
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      try {
        logo = pw.MemoryImage(base64Decode(logoBase64));
      } catch (_) {
        logo = null;
      }
    }
    pw.Widget detail(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(flex: 2, child: pw.Text(label,
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700))),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 3, child: pw.Text(value,
          textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5))),
      ]),
    );
    final blue = PdfColor.fromInt(0xFF29477A);
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, 160 * PdfPageFormat.mm),
      margin: const pw.EdgeInsets.all(11),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          if (logo != null) pw.Center(child: pw.Image(logo, width: 40, height: 40)),
          pw.SizedBox(height: 8),
          pw.Text(studioName,
            maxLines: 2, textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: blue)),
          pw.SizedBox(height: 5),
          pw.Text('CONSTANCIA INTERNA DE PAGO',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.Divider(color: PdfColors.grey500),
          detail('Número', '#' + payment.id.toString().padLeft(6, '0')),
          detail('Fecha de cobro', formatDate(payment.paidAt)),
          pw.SizedBox(height: 8),
          pw.Text('Cliente', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text(payment.clientName, style: pw.TextStyle(
            fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          detail('Plan', payment.planName),
          detail('Medio', payment.method),
          detail('Inicio período', formatDate(payment.periodStart)),
          pw.Divider(color: PdfColors.grey500),
          pw.Text('TOTAL ABONADO', textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 3),
          pw.Text(formatMoney(payment.amountCents),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: blue)),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(5)),
            child: pw.Column(children: [
              pw.Text('PRÓXIMO VENCIMIENTO',
                textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 5),
              pw.Text(formatDate(payment.periodEnd),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
          if (payment.voided) ...[
            pw.SizedBox(height: 8),
            pw.Text('COBRO ANULADO - SIN VALIDEZ',
              style: pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center),
          ],
          pw.Spacer(),
          pw.Text('Constancia interna del estudio. No válida como factura fiscal.',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
        ],
      ),
    ));
    return Uint8List.fromList(await pdf.save());
  }

  static String receiptFileName(StudioPayment payment) =>
      'comprobante-' + payment.id.toString().padLeft(6, '0') + '.pdf';

  static Future<Uint8List> _pdf(GymStore store, StudioPayment payment) =>
      buildTicketPdf(
        studioName: store.studioName, payment: payment,
        logoBase64: store.settings['studio_logo_b64'],
      );

  /// Guardar en la carpeta elegida por el usuario mediante Android SAF.
  static Future<void> saveToDevice(
    BuildContext context, GymStore store, StudioPayment payment,
  ) async {
    try {
      final bytes = await _pdf(store, payment);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar comprobante PDF',
        fileName: receiptFileName(payment),
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );
      if (path != null && context.mounted) {
        notice(context, 'Comprobante guardado.');
      }
    } catch (e) {
      if (context.mounted) {
        notice(context, 'No se pudo guardar el comprobante: $e');
      }
    }
  }

  /// Abre WhatsApp con el PDF preparado para el celular registrado.
  /// WhatsApp decide si abre el chat directo o solicita elegir el contacto;
  /// el envío final siempre lo confirma el usuario desde WhatsApp.
  static Future<void> sendToClient(
    BuildContext context, GymStore store, StudioPayment payment,
  ) async {
    if (payment.voided) {
      notice(context, 'El cobro está anulado; no se puede enviar como pago válido.');
      return;
    }
    final phone = store.clientById(payment.clientId)?.phone ?? '';
    final digits = whatsappPhone(phone);
    if (digits == null) {
      notice(context, 'Primero cargá el celular del cliente, con código de país, '
        'desde su ficha. Si es argentino, la app agrega +54 9 automáticamente.');
      return;
    }
    try {
      final bytes = await _pdf(store, payment);
      final result = await WhatsAppShare.share(
        phone: '+' + digits,
        text: 'Hola ' + payment.clientName + ', te compartimos tu '
            'constancia de pago de ' + store.studioName +
            '. Vencimiento: ' + formatDate(payment.periodEnd) + '.',
        files: [ShareFile.fromBytes(bytes, name: receiptFileName(payment))],
        allowFallback: false,
      );
      if (!context.mounted) return;
      if (result.status == ShareStatus.sheetPresented) {
        notice(context, 'WhatsApp solicita elegir el destinatario. '
          'Seleccioná el cliente y confirmá el envío del PDF.');
      }
      if (result.status == ShareStatus.fallback) {
        notice(context, 'WhatsApp no pudo adjuntar el PDF. '
          'Usá Guardar comprobante para conservarlo.');
      }
    } catch (e) {
      if (context.mounted) {
        notice(context, 'No se pudo abrir WhatsApp con el comprobante: $e');
      }
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

}

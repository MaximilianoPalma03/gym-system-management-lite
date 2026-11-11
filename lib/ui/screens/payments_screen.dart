import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../data/models.dart';
import '../../state/gym_store.dart';
import '../widgets/common.dart';
import '../widgets/payment_form.dart';
import '../../services/receipt_service.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key, required this.store});
  final GymStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store, builder: (context, _) {
      final now = DateTime.now();
      final monthPayments = store.payments.where((p) => !p.voided &&
        p.paidAt.month == now.month && p.paidAt.year == now.year);
      final sum = monthPayments.fold<int>(0, (acc, p) => acc + p.amountCents);
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ContentCard(child: Row(children: [
              const Icon(Icons.account_balance_wallet_outlined),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Cobrado este mes'),
                Text(formatMoney(sum), style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700)),
              ])),
            ])),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: () => showPaymentForm(context, store),
              icon: const Icon(Icons.add), label: const Text('Nuevo cobro')),
            const SizedBox(height: 18),
            Align(alignment: Alignment.centerLeft, child: Text('Historial de cobros',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700))),
          ])),
        Expanded(child: store.payments.isEmpty
          ? const EmptyMessage(icon: Icons.receipt_long_outlined,
              title: 'Todavía no hay cobros',
              message: 'Cuando registres una cuota, aparecerá su movimiento acá.')
          : RefreshIndicator(onRefresh: store.refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: store.payments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final payment = store.payments[index];
                  return _PaymentRow(
                    payment: payment,
                    canVoid: !payment.voided && !store.payments.any(
                      (other) => other.clientId == payment.clientId
                          && !other.voided && other.id > payment.id),
                    onVoid: () => _void(context, payment),
                    onReceipt: () => ReceiptService.sendToClient(context, store, payment),
                    onSave: () => ReceiptService.saveToDevice(context, store, payment));
                },
              ))),
      ]);
    },
  );

  Future<void> _void(BuildContext context, StudioPayment payment) async {
    final confirmed = await showDialog<bool>(context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('¿Anular este cobro?'),
        content: Text('El pago de ' + formatMoney(payment.amountCents) +
          ' dejará de contar en informes y se recalculará el vencimiento del cliente. El historial se conserva.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Anular cobro')),
        ],
      ));
    if (confirmed != true) return;
    try {
      await store.modify(() => store.repo.voidPayment(payment.id));
      if (context.mounted) notice(context, 'Cobro anulado');
    } catch (e) {
      if (context.mounted) notice(context, 'No se pudo anular: $e');
    }
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.canVoid, required this.onVoid,
    required this.onReceipt, required this.onSave});
  final StudioPayment payment;
  final bool canVoid;
  final VoidCallback onVoid;
  final VoidCallback onReceipt;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) => ContentCard(child: Row(children: [
    CircleAvatar(child: Icon(payment.voided ? Icons.block : Icons.payments_outlined)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(payment.clientName, style: const TextStyle(fontWeight: FontWeight.w600)),
      Text(payment.planName + ' · ' + payment.method,
        style: Theme.of(context).textTheme.bodySmall),
      Text(formatDate(payment.paidAt) + (payment.voided ? ' · ANULADO' : ''),
        style: TextStyle(color: payment.voided ? Colors.red : null, fontSize: 12)),
    ])),
    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(formatMoney(payment.amountCents), style: TextStyle(
        fontWeight: FontWeight.w700,
        decoration: payment.voided ? TextDecoration.lineThrough : null)),
      PopupMenuButton<String>(
        tooltip: 'Acciones sobre cobro',
        icon: const Icon(Icons.more_horiz),
        onSelected: (action) {
          if (action == 'share') onReceipt();
          if (action == 'save') onSave();
          if (action == 'void') onVoid();
        },
        itemBuilder: (_) => [
          if (!payment.voided)
            const PopupMenuItem(value: 'share', child: Text('Compartir comprobante')),
          const PopupMenuItem(value: 'save', child: Text('Guardar comprobante')),
          if (canVoid)
            const PopupMenuItem(value: 'void', child: Text('Anular último cobro')),
        ],
      ),
    ]),
  ]));
}

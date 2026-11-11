import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../state/gym_store.dart';
import '../widgets/common.dart';
import '../../services/receipt_service.dart';

class ClientHistoryScreen extends StatelessWidget {
  const ClientHistoryScreen({super.key, required this.store, required this.clientId});
  final GymStore store;
  final int clientId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final client = store.clientById(clientId);
      if (client == null) {
        return const Scaffold(body: Center(child: Text('Cliente no encontrado.')));
      }
      final history = store.payments.where((p) => p.clientId == clientId).toList();
      final valid = history.where((p) => !p.voided).toList();
      final amount = valid.fold<int>(0, (sum, p) => sum + p.amountCents);
      return Scaffold(
        appBar: AppBar(title: Text('Historial de ' + client.name,
          overflow: TextOverflow.ellipsis)),
        body: SafeArea(child: RefreshIndicator(
          onRefresh: store.refresh,
          child: ListView(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: ContentCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(client.name, style: Theme.of(context).textTheme.titleLarge),
                if (client.phone.isNotEmpty) Text('Teléfono: ' + client.phone),
                Text('Vencimiento actual: ' + formatDate(client.dueDate)),
                Text('Situación: ' + (client.active ? 'Activo' : 'Inactivo')),
                const Divider(height: 24),
                Text('Total de cobros válidos: ' + formatMoney(amount),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(valid.length.toString() + ' cobros registrados',
                  style: Theme.of(context).textTheme.bodySmall),
              ]))),
            Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text('Movimientos', style: Theme.of(context).textTheme.titleMedium)),
            if (history.isEmpty)
              const Padding(padding: EdgeInsets.all(16),
                child: ContentCard(child: Text('Este cliente todavía no tiene cobros registrados.')))
            else ...history.map((payment) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ContentCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(payment.planName,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text(formatMoney(payment.amountCents),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: payment.voided ? TextDecoration.lineThrough : null)),
                ]),
                const SizedBox(height: 4),
                Text(payment.method + ' · ' + formatDate(payment.paidAt)),
                Text('Vigencia: ' + formatDate(payment.periodStart) +
                  ' al ' + formatDate(payment.periodEnd),
                  style: Theme.of(context).textTheme.bodySmall),
                if (payment.notes.isNotEmpty) Text(payment.notes),
                if (payment.voided) const Text('COBRO ANULADO',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => ReceiptService.share(context, store, payment),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Compartir constancia'),
                ),
              ])),
            )),
            const SizedBox(height: 24),
          ]),
        )),
      );
    },
  );
}

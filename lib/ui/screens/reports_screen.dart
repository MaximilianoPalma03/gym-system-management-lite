import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/formatters.dart';
import '../../data/models.dart';
import '../../state/gym_store.dart';
import '../widgets/common.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.store});
  final GymStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store, builder: (context, _) {
      final now = DateTime.now();
      final valid = store.payments.where((p) => !p.voided).toList();
      int monthSum(DateTime m) => valid.where((p) => p.paidAt.year == m.year
          && p.paidAt.month == m.month).fold<int>(0, (sum, p) => sum + p.amountCents);
      final six = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i)));
      final values = six.map(monthSum).toList();
      final maxValue = math.max(1, values.fold<int>(0, math.max));
      final monthPayments = valid.where((p) => p.paidAt.year == now.year
        && p.paidAt.month == now.month).toList();
      final methods = <String, int>{};
      for (final p in monthPayments) {
        methods[p.method] = (methods[p.method] ?? 0) + p.amountCents;
      }
      return RefreshIndicator(onRefresh: store.refresh, child: ListView(children: [
        PagePadding(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Informes de cobros', style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Solo pagos registrados: sin cobros anulados ni gastos.',
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ContentCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ingresos de este mes'),
            const SizedBox(height: 6),
            Text(formatMoney(monthSum(DateTime(now.year, now.month))),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(monthPayments.length.toString() + ' cobros',
              style: Theme.of(context).textTheme.bodySmall),
          ])),
          const SizedBox(height: 14),
          ContentCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Últimos 6 meses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            for (var i = 0; i < six.length; i++) ...[
              Row(children: [
                SizedBox(width: 46, child: Text(DateFormat('MMM', 'es_AR').format(six[i]),
                  style: const TextStyle(fontSize: 12))),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: values[i] / maxValue, minHeight: 14,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest))),
                const SizedBox(width: 10),
                SizedBox(width: 105, child: Text(formatMoney(values[i]),
                  textAlign: TextAlign.end, style: const TextStyle(fontSize: 12))),
              ]),
              const SizedBox(height: 14),
            ],
          ])),
          const SizedBox(height: 14),
          ContentCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Por medio de pago · mes actual', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (methods.isEmpty) const Text('Todavía no hay cobros este mes.'),
            ...methods.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Expanded(child: Text(entry.key)),
                Text(formatMoney(entry.value), style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            )),
          ])),
          const SizedBox(height: 16),
          _AllTimeStats(payments: valid, clients: store.clients),
        ])),
      ]));
    },
  );
}

class _AllTimeStats extends StatelessWidget {
  const _AllTimeStats({required this.payments, required this.clients});
  final List<StudioPayment> payments;
  final List<StudioClient> clients;
  @override
  Widget build(BuildContext context) {
    final total = payments.fold<int>(0, (sum, p) => sum + p.amountCents);
    return ContentCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Resumen histórico', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      Text('Total registrado: ' + formatMoney(total)),
      Text('Cobros registrados: ' + payments.length.toString()),
      Text('Clientes registrados: ' + clients.length.toString()),
      const SizedBox(height: 6),
      Text('Pendientes se calcula por fecha de vencimiento, no por importe adeudado.',
        style: Theme.of(context).textTheme.bodySmall),
    ]));
  }
}

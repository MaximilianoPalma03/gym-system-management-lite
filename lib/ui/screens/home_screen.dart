import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../core/client_activity.dart';
import '../../data/models.dart';
import '../../state/gym_store.dart';
import '../widgets/common.dart';
import '../widgets/payment_form.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store, required this.onClients});
  final GymStore store;
  final VoidCallback onClients;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final today = day(DateTime.now());
      final valid = store.payments.where((p) => !p.voided).toList();
      int totalMonth(int year, int month) => valid
        .where((p) => p.paidAt.year == year && p.paidAt.month == month)
        .fold(0, (int sum, p) => sum + p.amountCents);
      final income = totalMonth(today.year, today.month);
      final before = DateTime(today.year, today.month - 1);
      final prior = totalMonth(before.year, before.month);
      ClientActivity status(StudioClient c) => clientActivity(c,
        today: today, inactiveAfterDays: store.inactiveAfterDays);
      final active = store.clients.where((c) =>
        status(c) == ClientActivity.vigente).length;
      final pending = store.clients.where((c) =>
        status(c) == ClientActivity.pendiente).length;
      final upcoming = store.clients.where((c) => c.active && c.dueDate != null
          && compareDays(c.dueDate!, today) >= 0
          && compareDays(c.dueDate!, today.add(const Duration(days: 7))) <= 0).toList()
        ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      final delta = prior == 0 ? 'Sin ingresos el mes anterior'
          : (income >= prior ? '+' : '') +
            (((income - prior) / prior) * 100).toStringAsFixed(1) + '% vs. mes anterior';
      final color = Theme.of(context).colorScheme.primary;
      return RefreshIndicator(onRefresh: store.refresh,
        child: ListView(children: [
          PagePadding(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Resumen del negocio', style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(formatDate(today), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Ingresos registrados este mes', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Text(formatMoney(income), style: const TextStyle(
                  color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(delta, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Kpi(icon: Icons.people_outline, title: 'Cuotas vigentes', value: '$active')),
              const SizedBox(width: 10),
              Expanded(child: _Kpi(icon: Icons.schedule_outlined, title: 'Pendientes', value: '$pending')),
            ]),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text('Próximos vencimientos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              TextButton(onPressed: onClients, child: const Text('Ver clientes')),
            ]),
            const SizedBox(height: 10),
            if (upcoming.isEmpty)
              const ContentCard(child: Text('No hay vencimientos en los próximos 7 días.'))
            else
              ...upcoming.take(5).map((c) => Padding(padding: const EdgeInsets.only(bottom: 8),
                child: _Upcoming(client: c,
                  plan: c.planId == null ? null : store.planById(c.planId!)))),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => showPaymentForm(context, store),
              icon: const Icon(Icons.add), label: const Text('Registrar nuevo pago'),
            ),
            const SizedBox(height: 12),
            Text('Los importes son cobros anotados en esta app, no ganancias netas.',
              style: Theme.of(context).textTheme.bodySmall),
          ])),
        ]),
      );
    },
  );
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => ContentCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 8),
      Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(title, style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}
class _Upcoming extends StatelessWidget {
  const _Upcoming({required this.client, this.plan});
  final StudioClient client;
  final StudioPlan? plan;
  @override
  Widget build(BuildContext context) => ContentCard(child: Row(children: [
    CircleAvatar(child: Text(client.name.isEmpty ? '?' : client.name[0].toUpperCase())),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(client.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      Text((plan?.name ?? 'Sin plan') + ' · ' + formatDate(client.dueDate),
        style: Theme.of(context).textTheme.bodySmall),
    ])),
    const Icon(Icons.event_outlined, size: 20),
  ]));
}

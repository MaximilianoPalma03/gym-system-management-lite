import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../data/models.dart';
import '../../state/gym_store.dart';
import 'client_history_screen.dart';
import '../widgets/client_form.dart';
import '../widgets/common.dart';
import '../widgets/payment_form.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key, required this.store});
  final GymStore store;
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final search = TextEditingController();
  bool showInactive = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final query = search.text.trim().toLowerCase();
      final visible = widget.store.clients.where((c) =>
        (c.active || showInactive) &&
        (c.name.toLowerCase().contains(query) || c.phone.contains(query))).toList();
      final today = day(DateTime.now());
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Column(children: [
          TextField(controller: search, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nombre o teléfono')),
          const SizedBox(height: 8),
          Row(children: [
            FilterChip(label: const Text('Incluir inactivos'), selected: showInactive,
              onSelected: (v) => setState(() => showInactive = v)),
            const Spacer(),
            Text(visible.length.toString() + ' clientes', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ])),
        Expanded(child: visible.isEmpty
          ? const EmptyMessage(icon: Icons.people_outline, title: 'Sin clientes',
              message: 'Registrá tu primer cliente con el botón inferior.')
          : RefreshIndicator(onRefresh: widget.store.refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: visible.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final c = visible[index];
                  final expired = c.dueDate == null || compareDays(c.dueDate!, today) < 0;
                  final status = !c.active ? 'Inactivo' : expired ? 'Pendiente' : 'Vigente';
                  return ContentCard(onTap: () => _showClient(context, c),
                    child: Row(children: [
                      CircleAvatar(child: Text(c.name.substring(0, 1).toUpperCase())),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (c.phone.isNotEmpty)
                          Text(c.phone, style: Theme.of(context).textTheme.bodySmall),
                        Text(status + ' · ' + formatDate(c.dueDate),
                          style: TextStyle(fontSize: 12, color: !c.active ? Colors.grey
                            : expired ? Colors.deepOrange : Colors.teal)),
                      ])),
                      const Icon(Icons.chevron_right),
                    ]));
                },
              ),
            )),
        Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Align(alignment: Alignment.centerRight,
            child: FloatingActionButton.extended(
              onPressed: () => showClientForm(context, widget.store),
              icon: const Icon(Icons.person_add_alt_1), label: const Text('Nuevo cliente')))),
      ]);
    },
  );

  Future<void> _showClient(BuildContext context, StudioClient client) async {
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheet) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(client.name, style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Vencimiento: ' + formatDate(client.dueDate)),
            if (client.phone.isNotEmpty) Text('Teléfono: ' + client.phone),
            if (client.notes.isNotEmpty) Text('Notas: ' + client.notes),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: client.active ? () {
              Navigator.pop(sheet);
              showPaymentForm(context, widget.store, clientId: client.id);
            } : null, icon: const Icon(Icons.payments_outlined), label: const Text('Registrar pago')),
            OutlinedButton.icon(onPressed: () {
              Navigator.pop(sheet);
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ClientHistoryScreen(store: widget.store, clientId: client.id)));
            }, icon: const Icon(Icons.history), label: const Text('Historial de cobros')),
            OutlinedButton.icon(onPressed: () {
              Navigator.pop(sheet);
              showClientForm(context, widget.store, client: client);
            }, icon: const Icon(Icons.edit_outlined), label: const Text('Editar cliente')),
            TextButton(onPressed: () async {
              Navigator.pop(sheet);
              try {
                await widget.store.modify(
                  () => widget.store.repo.setClientActive(client.id, !client.active));
                if (context.mounted) {
                  notice(context, client.active ? 'Cliente desactivado' : 'Cliente reactivado');
                }
              } catch (e) {
                if (context.mounted) notice(context, 'Error: $e');
              }
            }, child: Text(client.active ? 'Desactivar cliente' : 'Reactivar cliente')),
          ]),
      )),
    );
  }
}

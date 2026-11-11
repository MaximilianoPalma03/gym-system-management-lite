import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/formatters.dart';
import '../../state/gym_store.dart';
import 'common.dart';

Future<void> showPaymentForm(BuildContext context, GymStore store, {int? clientId}) async {
  if (store.clients.where((c) => c.active).isEmpty) {
    notice(context, 'Primero registrá un cliente activo.');
    return;
  }
  if (store.plans.where((p) => p.active).isEmpty) {
    notice(context, 'Primero configurá un plan en Ajustes.');
    return;
  }
  await showModalBottomSheet<void>(
    context: context, isScrollControlled: true, showDragHandle: true,
    builder: (_) => _PaymentForm(store: store, initialClientId: clientId),
  );
}

class _PaymentForm extends StatefulWidget {
  const _PaymentForm({required this.store, this.initialClientId});
  final GymStore store;
  final int? initialClientId;
  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  final key = GlobalKey<FormState>();
  final money = TextEditingController();
  final notes = TextEditingController();
  int? clientId;
  int? planId;
  String method = 'Efectivo';
  DateTime paidAt = DateTime.now();
  bool saving = false;
  bool editedAmount = false;

  @override
  void initState() {
    super.initState();
    final customers = widget.store.clients.where((c) => c.active).toList();
    final plans = widget.store.plans.where((p) => p.active).toList();
    clientId = customers.any((c) => c.id == widget.initialClientId)
        ? widget.initialClientId : customers.first.id;
    planId = plans.first.id;
    _suggestAmount();
  }

  void _suggestAmount() {
    if (editedAmount) return;
    final plan = widget.store.planById(planId!);
    money.text = plan == null ? '' : (plan.priceCents / 100).toStringAsFixed(0);
  }
  @override
  void dispose() {
    money.dispose(); notes.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !key.currentState!.validate()) return;
    final amount = parseMoney(money.text);
    if (amount == null || amount <= 0) {
      notice(context, 'Ingresá un importe mayor a cero.');
      return;
    }
    setState(() => saving = true);
    try {
      await widget.store.modify(() => widget.store.repo.recordPayment(
        clientId: clientId!, planId: planId!, amountCents: amount,
        method: method, paidAt: paidAt, notes: notes.text));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) notice(context, 'No se pudo guardar el cobro: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = widget.store.clients.where((c) => c.active).toList();
    final plans = widget.store.plans.where((p) => p.active).toList();
    return SafeArea(child: Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(child: Form(key: key, child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Registrar cobro', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: clientId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Cliente'),
            items: customers.map((c) => DropdownMenuItem(value: c.id,
              child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => clientId = v),
            validator: (v) => v == null ? 'Elegí un cliente.' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: planId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Plan'),
            items: plans.map((p) => DropdownMenuItem(value: p.id,
              child: Text(p.name + ' · ' + formatMoney(p.priceCents),
                overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) {
              setState(() => planId = v);
              _suggestAmount();
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
            onChanged: (_) => editedAmount = true,
            decoration: const InputDecoration(labelText: 'Importe cobrado (ARS) *',
              prefixText: r'$ '),
            validator: (v) => (parseMoney(v ?? '') ?? 0) <= 0 ? 'Ingresá un importe válido.' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: method,
            decoration: const InputDecoration(labelText: 'Medio de pago'),
            items: ['Efectivo', 'Transferencia', 'Tarjeta', 'Otro']
              .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => method = v ?? method),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final value = await showDatePicker(context: context,
                initialDate: paidAt, firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)));
              if (value != null) setState(() => paidAt = value);
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('Fecha del cobro: ' + formatDate(paidAt)),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: notes, maxLength: 500,
            decoration: const InputDecoration(labelText: 'Observaciones (opcional)')),
          const SizedBox(height: 12),
          Text('La renovación comienza luego del vencimiento vigente o en la fecha del cobro.',
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          FilledButton(onPressed: saving ? null : save,
            child: Text(saving ? 'Guardando...' : 'Guardar cobro')),
        ],
      ))),
    ));
  }
}

import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../state/gym_store.dart';
import 'common.dart';

Future<void> showClientForm(BuildContext context, GymStore store, {StudioClient? client}) async {
  await showModalBottomSheet<void>(
    context: context, isScrollControlled: true, showDragHandle: true,
    builder: (_) => _ClientForm(store: store, client: client),
  );
}

class _ClientForm extends StatefulWidget {
  const _ClientForm({required this.store, this.client});
  final GymStore store;
  final StudioClient? client;
  @override
  State<_ClientForm> createState() => _ClientFormState();
}
class _ClientFormState extends State<_ClientForm> {
  final key = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.client?.name ?? '');
  late final phone = TextEditingController(text: widget.client?.phone ?? '');
  late final notes = TextEditingController(text: widget.client?.notes ?? '');
  bool saving = false;
  @override
  void dispose() {
    name.dispose(); phone.dispose(); notes.dispose();
    super.dispose();
  }
  Future<void> save() async {
    if (!key.currentState!.validate() || saving) return;
    setState(() => saving = true);
    try {
      await widget.store.modify(() => widget.store.repo.saveClient(
        id: widget.client?.id, name: name.text, phone: phone.text,
        notes: notes.text, active: widget.client?.active ?? true));
      if (!mounted) return;
      Navigator.pop(context);
      notice(context, 'Cliente guardado correctamente.');
    } catch (e) {
      if (mounted) notice(context, 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(
    padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.viewInsetsOf(context).bottom + 22),
    child: SingleChildScrollView(child: Form(key: key, child: Column(
      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.client == null ? 'Nuevo cliente' : 'Editar cliente',
          style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 18),
        TextFormField(controller: name, autofocus: true,
          textCapitalization: TextCapitalization.words, maxLength: 100,
          decoration: const InputDecoration(labelText: 'Nombre y apellido *'),
          validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Ingresá el nombre completo.' : null),
        TextFormField(controller: phone, keyboardType: TextInputType.phone, maxLength: 40,
          decoration: const InputDecoration(labelText: 'Teléfono (opcional)')),
        TextFormField(controller: notes, maxLines: 2, maxLength: 500,
          decoration: const InputDecoration(labelText: 'Notas (opcional)')),
        const SizedBox(height: 8),
        FilledButton(onPressed: saving ? null : save,
          child: Text(saving ? 'Guardando...' : 'Guardar cliente')),
      ],
    ))),
  ));
}

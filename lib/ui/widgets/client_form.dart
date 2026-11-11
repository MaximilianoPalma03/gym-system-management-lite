import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../core/phones.dart';
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
  String country = 'AR';

  @override
  void initState() {
    super.initState();
    final raw = widget.client?.phone ?? '';
    if (raw.startsWith('+56')) country = 'CL';
    else if (raw.startsWith('+55')) country = 'BR';
    else if (raw.startsWith('+') && !raw.startsWith('+54')) country = 'OTHER';
  }
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
        id: widget.client?.id, name: name.text,
        phone: normalizePhone(phone.text, country),
        notes: notes.text, active: widget.client?.active ?? true));
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Cliente guardado correctamente.')));
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
        DropdownButtonFormField<String>(
          value: country,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'País del teléfono'),
          items: const [
            DropdownMenuItem(value: 'AR', child: Text('Argentina (+54 9)')),
            DropdownMenuItem(value: 'CL', child: Text('Chile (+56)')),
            DropdownMenuItem(value: 'BR', child: Text('Brasil (+55)')),
            DropdownMenuItem(value: 'OTHER', child: Text('Otro (+código completo)')),
          ],
          onChanged: (value) => setState(() => country = value ?? 'AR'),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: phone, keyboardType: TextInputType.phone, maxLength: 40,
          decoration: InputDecoration(
            labelText: 'Celular (opcional)',
            hintText: country == 'AR' ? '3511234567, sin 0 ni 15'
                : country == 'OTHER' ? '+código internacional y número' : 'Número local',
          ),
          validator: (value) {
            try {
              normalizePhone(value ?? '', country);
              return null;
            } on FormatException catch (e) {
              return e.message;
            }
          },
        ),
        TextFormField(controller: notes, maxLines: 2, maxLength: 500,
          decoration: const InputDecoration(labelText: 'Notas (opcional)')),
        const SizedBox(height: 8),
        FilledButton(onPressed: saving ? null : save,
          child: Text(saving ? 'Guardando...' : 'Guardar cliente')),
      ],
    ))),
  ));
}

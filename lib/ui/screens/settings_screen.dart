import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/formatters.dart';
import '../../core/billing.dart';
import '../../data/models.dart';
import '../../services/backup_service.dart';
import '../../state/gym_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});
  final GymStore store;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final name = TextEditingController(text: widget.store.studioName);
  bool working = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final value = name.text.trim();
    if (value.length < 2 || value.length > 70) {
      notice(context, 'El nombre debe tener entre 2 y 70 caracteres.');
      return;
    }
    try {
      await widget.store.modify(() => widget.store.repo.saveSetting('studio_name', value));
      if (mounted) notice(context, 'Nombre actualizado.');
    } catch (e) {
      if (mounted) notice(context, 'Error: $e');
    }
  }

  Future<void> _chooseLogo() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.image, withData: true, allowMultiple: false);
      if (!mounted || picked == null || picked.files.isEmpty) return;
      final f = picked.files.single;
      Uint8List? bytes = f.bytes;
      if (bytes == null && f.path != null) bytes = await File(f.path!).readAsBytes();
      if (bytes == null || bytes.isEmpty) {
        notice(context, 'No se pudo leer el logo.');
        return;
      }
      if (bytes.length > 350000) {
        notice(context, 'Elegí una imagen PNG o JPG de menos de 350 KB.');
        return;
      }
      await widget.store.modify(
        () => widget.store.repo.saveSetting('studio_logo_b64', base64Encode(bytes!)));
      if (mounted) notice(context, 'Logo actualizado.');
    } catch (e) {
      if (mounted) notice(context, 'No se pudo cambiar el logo: $e');
    }
  }

  Future<void> _clearLogo() async {
    await widget.store.modify(() => widget.store.repo.saveSetting('studio_logo_b64', ''));
    if (mounted) notice(context, 'Logo quitado.');
  }

  Future<void> _changeColor(int index) async {
    await widget.store.modify(() => widget.store.repo.saveSetting('color_index', index.toString()));
  }

  Future<void> _changeTheme(String theme) async {
    await widget.store.modify(() => widget.store.repo.saveSetting('theme_mode', theme));
  }

  /// El diálogo conserva sus propios campos durante su animación de salida.
  /// No destruimos TextEditingControllers justo después del Navigator.pop:
  /// eso producía un fallo de widgets durante guardar/compartir/restaurar.
  Future<String?> _askPassword({required bool confirmation}) async {
    String password = '';
    String repeated = '';
    return showDialog<String>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: Text(confirmation ? 'Contraseña del respaldo' : 'Abrir respaldo'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(confirmation
                ? 'Elegí una contraseña de al menos 8 caracteres. La necesitarás para recuperar tus datos.'
                : 'Ingresá la contraseña con la que se creó el respaldo.'),
            const SizedBox(height: 12),
            TextField(
              obscureText: true, autocorrect: false, enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              onChanged: (v) => update(() => password = v),
            ),
            if (confirmation) ...[
              const SizedBox(height: 12),
              TextField(
                obscureText: true, autocorrect: false, enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'Repetir contraseña'),
                onChanged: (v) => update(() => repeated = v),
              ),
            ],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancelar')),
            FilledButton(
              onPressed: password.length >= (confirmation ? 8 : 1)
                  && (!confirmation || repeated == password)
                  ? () => Navigator.pop(dialog, password)
                  : null,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export({bool share = false}) async {
    final password = await _askPassword(confirmation: true);
    if (!mounted || password == null || working) return;
    setState(() => working = true);
    try {
      final bytes = await BackupService(widget.store.repo).exportEncrypted(password);
      final filename = 'gym-lite-' + dateKey(DateTime.now()) + '.gymlite';
      if (share) {
        final params = ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/octet-stream')],
          fileNameOverrides: [filename],
          text: 'Respaldo cifrado de Higea Fitness',
        );
        final result = await SharePlus.instance.share(params);
        if (mounted) {
          notice(context, result.status == ShareResultStatus.dismissed
            ? 'No se confirmó el guardado. Guardá una copia fuera del celular.'
            : 'Verificá que el respaldo se haya guardado fuera del teléfono.');
        }
      } else {
        final saved = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar respaldo protegido',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['gymlite'],
          bytes: bytes,
        );
        if (mounted) notice(context, saved == null
          ? 'Guardado cancelado.'
          : 'Respaldo exportado. Conservá la contraseña en un lugar seguro.');
      }
    } catch (e) {
      if (mounted) notice(context, 'No se pudo exportar: $e');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _import() async {
    if (working) return;
    try {
      final files = await FilePicker.platform.pickFiles(type: FileType.any,
        allowMultiple: false, withData: true);
      if (!mounted || files == null || files.files.isEmpty) return;
      final selected = files.files.single;
      if (!selected.name.toLowerCase().endsWith('.gymlite')) {
        notice(context, 'Seleccioná un archivo .gymlite.');
        return;
      }
      Uint8List? bytes = selected.bytes;
      if (bytes == null && selected.path != null) {
        bytes = await File(selected.path!).readAsBytes();
      }
      if (!mounted) return;
      if (bytes == null) {
        notice(context, 'No fue posible leer el archivo.');
        return;
      }
      final password = await _askPassword(confirmation: false);
      if (!mounted || password == null) return;
      setState(() => working = true);
      // Autenticación AES-GCM y descifrado antes de borrar datos locales.
      final decoded = await BackupService(widget.store.repo).decrypt(bytes, password);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('¿Reemplazar todos los datos?'),
          content: const Text('Esta acción reemplaza los clientes, planes, cobros y ajustes de este teléfono. '
            'Antes de continuar, exportá un respaldo de los datos actuales.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Restaurar todo')),
          ],
        ));
      if (confirmed != true) return;
      await widget.store.repo.restoreData(decoded);
      await widget.store.refresh();
      if (mounted) {
        name.text = widget.store.studioName;
        notice(context, 'Respaldo restaurado correctamente.');
      }
    } catch (e) {
      if (mounted) notice(context,
        'No se pudo restaurar. Verificá el archivo y la contraseña. ($e)');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Ajustes del estudio')),
      body: SafeArea(child: ListView(children: [
        PagePadding(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          ContentCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text('Identidad del estudio', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            TextField(controller: name, maxLength: 70,
              decoration: const InputDecoration(labelText: 'Nombre del estudio')),
            FilledButton.tonalIcon(onPressed: _saveName,
              icon: const Icon(Icons.save_outlined), label: const Text('Guardar nombre')),
            const SizedBox(height: 18),
            Row(children: [
              const Expanded(child: Text('Logo dentro de la aplicación')),
              TextButton.icon(onPressed: _chooseLogo, icon: const Icon(Icons.image_outlined),
                label: const Text('Elegir')),
            ]),
            if ((widget.store.settings['studio_logo_b64'] ?? '').isNotEmpty)
              Row(children: [
                const Text('Logo guardado para este estudio'),
                const Spacer(),
                TextButton(onPressed: _clearLogo, child: const Text('Quitar')),
              ]),
            const Text('El ícono del escritorio Android identifica a Higea Fitness. '
              'El nombre y el logo de este estudio son personalizables dentro de la app.',
              style: TextStyle(fontSize: 12)),
            const SizedBox(height: 18),
            const Text('Apariencia'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final mode in const ['light', 'dark', 'system'])
                ChoiceChip(
                  label: Text(mode == 'light' ? 'Claro' :
                    mode == 'dark' ? 'Oscuro' : 'Sistema'),
                  selected: widget.store.themeMode.name == mode,
                  onSelected: (_) => _changeTheme(mode),
                ),
            ]),
            const SizedBox(height: 20),
            const Text('Color principal'),
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 10, children: [
              for (var i = 0; i < studioColors.length; i++)
                InkWell(onTap: () => _changeColor(i),
                  borderRadius: BorderRadius.circular(30),
                  child: CircleAvatar(radius: 22, backgroundColor: studioColors[i],
                    child: widget.store.colorIndex == i
                      ? const Icon(Icons.check, color: Colors.white) : null)),
            ]),
          ])),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Text('Planes y precios',
              style: Theme.of(context).textTheme.titleLarge)),
            TextButton.icon(onPressed: () => _showPlanEditor(context),
              icon: const Icon(Icons.add), label: const Text('Nuevo')),
          ]),
          const SizedBox(height: 8),
          if (widget.store.plans.isEmpty)
            const ContentCard(child: Text('No hay planes configurados.'))
          else ...widget.store.plans.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ContentCard(onTap: () => _showPlanEditor(context, plan: p),
              child: Row(children: [
                const Icon(Icons.card_membership_outlined),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name + (p.active ? '' : ' (inactivo)'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text((p.isCalendarMonthly ? p.cycleMonths.toString() + ' mes(es) calendario' : p.durationDays.toString() + ' días fijos') + ' · ' + formatMoney(p.priceCents),
                    style: Theme.of(context).textTheme.bodySmall),
                ])),
                const Icon(Icons.edit_outlined),
              ]),
            ),
          )),
          const SizedBox(height: 16),
          Text('Datos y respaldo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ContentCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Cada instalación guarda datos exclusivamente en este teléfono.'),
            const SizedBox(height: 8),
            const Text('Exportá respaldos periódicos a otra ubicación. Si desinstalás '
              'la aplicación, los datos locales pueden perderse.'),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: working ? null : () => _export(),
              icon: const Icon(Icons.save_alt_outlined),
              label: Text(working ? 'Procesando...' : 'Guardar respaldo cifrado')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: working ? null : () => _export(share: true),
              icon: const Icon(Icons.ios_share_outlined),
              label: const Text('Compartir respaldo')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: working ? null : _import,
              icon: const Icon(Icons.restore_outlined),
              label: const Text('Restaurar desde archivo')),
          ])),
          const SizedBox(height: 18),
          const Text('Higea Fitness · Versión de prueba · Uso local y offline.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
      ])),
    ),
  );

  Future<void> _showPlanEditor(BuildContext context, {StudioPlan? plan}) async {
    await showDialog<void>(context: context, builder: (_) =>
      _PlanEditor(store: widget.store, plan: plan));
  }
}

class _PlanEditor extends StatefulWidget {
  const _PlanEditor({required this.store, this.plan});
  final GymStore store;
  final StudioPlan? plan;
  @override
  State<_PlanEditor> createState() => _PlanEditorState();
}
class _PlanEditorState extends State<_PlanEditor> {
  final key = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.plan?.name ?? '');
  late final price = TextEditingController(
    text: ((widget.plan?.priceCents ?? 0) / 100).toStringAsFixed(0));
  late final customNumber = TextEditingController(text: _customNumber.toString());
  late bool active = widget.plan?.active ?? true;
  late String duration = _initialDuration();
  late String customUnit = widget.plan?.cycleKind == 'months' ? 'months' : 'days';
  bool saving = false;

  int get _customNumber => widget.plan?.cycleKind == 'months'
      ? widget.plan!.cycleMonths : widget.plan?.durationDays ?? 30;

  String _initialDuration() {
    final plan = widget.plan;
    if (plan == null) return 'month';
    if (plan.cycleKind == 'months' && plan.cycleMonths == 1) return 'month';
    if (plan.cycleKind == 'days') {
      switch (plan.durationDays) {
        case 7: return 'week';
        case 15: return 'fortnight';
        case 30: return 'days30';
      }
    }
    return 'custom';
  }

  @override
  void dispose() {
    name.dispose();
    customNumber.dispose();
    price.dispose();
    super.dispose();
  }

  String get cycleKind => duration == 'month' ||
      (duration == 'custom' && customUnit == 'months') ? 'months' : 'days';

  int get cycleMonths => duration == 'month' ? 1
      : duration == 'custom' && customUnit == 'months'
          ? int.tryParse(customNumber.text) ?? 1 : 1;

  int get durationDays {
    switch (duration) {
      case 'week': return 7;
      case 'fortnight': return 15;
      case 'days30': return 30;
      case 'custom':
        return customUnit == 'months' ? 30 : int.tryParse(customNumber.text) ?? 30;
      default: return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ejemplo desde la fecha real del dispositivo al configurar el plan.
    final today = DateTime.now();
    DateTime? exampleDue;
    final custom = duration == 'custom' ? int.tryParse(customNumber.text) : null;
    final customValid = duration != 'custom' ||
        (custom != null && custom >= 1 &&
         custom <= (customUnit == 'months' ? 120 : 3650));
    if (customValid) {
      exampleDue = calculateBillingPeriod(
        paidAt: today, cycleKind: cycleKind,
        durationDays: durationDays, cycleMonths: cycleMonths,
      ).end;
    }

    return AlertDialog(
      title: Text(widget.plan == null ? 'Nuevo plan' : 'Editar plan'),
      content: SingleChildScrollView(child: Form(key: key, child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: name, maxLength: 70,
            decoration: const InputDecoration(labelText: 'Nombre del plan'),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Ingresá un nombre.' : null,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: duration,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Duración del plan'),
            items: const [
              DropdownMenuItem(value: 'month', child: Text('1 mes')),
              DropdownMenuItem(value: 'week', child: Text('7 días')),
              DropdownMenuItem(value: 'fortnight', child: Text('15 días')),
              DropdownMenuItem(value: 'days30', child: Text('30 días exactos')),
              DropdownMenuItem(value: 'custom', child: Text('Otra duración')),
            ],
            onChanged: (v) => setState(() => duration = v ?? duration),
          ),
          if (duration == 'custom') ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextFormField(
                controller: customNumber,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Cantidad'),
                validator: (value) {
                  if (duration != 'custom') return null;
                  final count = int.tryParse(value ?? '');
                  return count == null || count < 1 ||
                      count > (customUnit == 'months' ? 120 : 3650)
                      ? 'Duración inválida.' : null;
                },
              )),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(
                initialValue: customUnit,
                decoration: const InputDecoration(labelText: 'Unidad'),
                items: const [
                  DropdownMenuItem(value: 'days', child: Text('Días')),
                  DropdownMenuItem(value: 'months', child: Text('Meses')),
                ],
                onChanged: (value) =>
                    setState(() => customUnit = value ?? customUnit),
              )),
            ]),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ejemplo de vencimiento',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              Text('Si el cliente empieza hoy (' + formatDate(today) + '):'),
              Text(exampleDue == null ? 'Ingresá una duración válida.'
                : 'Vencería el ' + formatDate(exampleDue) + '.',
                style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(cycleKind == 'months'
                  ? 'Mantiene el mismo día de cada mes.'
                  : 'Suma la cantidad exacta de días contratados.',
                style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Precio sugerido (ARS)'),
            validator: (v) => parseMoney(v ?? '') == null ? 'Importe inválido.' : null,
          ),
          SwitchListTile(
            value: active, contentPadding: EdgeInsets.zero,
            title: const Text('Plan activo'),
            onChanged: (v) => setState(() => active = v),
          ),
          const Text('Los cambios de precio no modifican los cobros anteriores.',
            style: TextStyle(fontSize: 12)),
        ],
      ))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }

  Future<void> save() async {
    if (saving || !key.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.store.modify(() => widget.store.repo.savePlan(
        id: widget.plan?.id,
        name: name.text,
        durationDays: durationDays,
        cycleKind: cycleKind,
        cycleMonths: cycleMonths,
        priceCents: parseMoney(price.text)!,
        active: active,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) notice(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

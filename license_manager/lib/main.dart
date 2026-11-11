import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'license_issuer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LicenseManagerApp());
}

class LicenseManagerApp extends StatelessWidget {
  const LicenseManagerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Higea Fitness License Manager',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF314C8B)),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA)),
    home: const LicenseManagerHome(),
  );
}

class LicenseManagerHome extends StatefulWidget {
  const LicenseManagerHome({super.key});
  @override
  State<LicenseManagerHome> createState() => _LicenseManagerHomeState();
}

class _LicenseManagerHomeState extends State<LicenseManagerHome> {
  final issuer = LicenseIssuer();
  final controller = TextEditingController();
  Map<String, dynamic>? key;
  String? license;
  LicenseType licenseType = LicenseType.permanent;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    refresh();
  }
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> refresh() async {
    try {
      final current = await issuer.storedKey();
      if (mounted) setState(() { key = current; error = null; });
    } catch (e) {
      if (mounted) setState(() => error = 'No se pudo leer la clave: $e');
    }
  }

  Future<void> create() async {
    if (busy) return;
    final confirm = await showDialog<bool>(context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Crear clave maestra'),
        content: const Text('Esta clave emitirá todas las licencias. '
          'Antes de vender, guardá una copia externa desde esta aplicación.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Crear')),
        ]));
    if (confirm != true || !mounted) return;
    setState(() => busy = true);
    try {
      await issuer.createKey();
      await refresh();
      notify('Clave maestra creada. Guardá una copia externa.');
    } catch (e) {
      notify('No se pudo generar: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> issue() async {
    if (busy) return;
    final code = LicenseIssuer.normalizeInstallationCode(controller.text);
    if (!LicenseIssuer.isValidInstallationCode(code)) {
      notify('Pegá el código corto de instalación (8 caracteres).');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      final result = await issuer.issue(code, type: licenseType);
      if (mounted) setState(() => license = result);
    } catch (e) {
      if (mounted) setState(() => error = 'No se pudo generar: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final content = data?.text ?? '';
    final normalized = content.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    final matched = RegExp(r'[A-F0-9]{32}|[A-HJ-NP-Z2-9]{8}').firstMatch(normalized);
    if (matched == null) {
      notify('El portapapeles no tiene un código de instalación válido.');
      return;
    }
    controller.text = matched.group(0)!;
    setState(() => license = null);
  }

  Future<void> shareLicense() async {
    if (license == null) return;
    await SharePlus.instance.share(ShareParams(
      text: ((licenseType == LicenseType.trial)
          ? 'Tu clave de prueba gratuita de Higea Fitness (7 días):\n\n'
          : 'Tu licencia comercial permanente de Higea Fitness:\n\n') +
        license! + '\n\nCopiá y pegá la clave en la pantalla de activación.',
      title: 'Licencia Higea Fitness',
    ));
  }

  Future<void> backup() async {
    try {
      final bytes = await issuer.exportMasterKey();
      final selected = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar copia de la clave maestra',
        type: FileType.custom, allowedExtensions: ['gslkey'],
        fileName: 'gym-lite-master-key.gslkey', bytes: bytes);
      if (selected != null) notify('Copia guardada. Conservala fuera de este celular.');
    } catch (e) {
      notify('No se pudo guardar la clave: $e');
    }
  }

  Future<void> restore() async {
    try {
      final selected = await FilePicker.platform.pickFiles(
        type: FileType.any, allowMultiple: false, withData: true);
      if (!mounted || selected == null || selected.files.isEmpty) return;
      final item = selected.files.single;
      if (!item.name.endsWith('.gslkey')) {
        notify('El archivo debe terminar en .gslkey');
        return;
      }
      Uint8List? bytes = item.bytes;
      if (bytes == null && item.path != null) bytes = await File(item.path!).readAsBytes();
      if (!mounted || bytes == null) return;
      final replacing = key != null;
      if (replacing) {
        final ok = await showDialog<bool>(context: context,
          builder: (dialog) => AlertDialog(
            title: const Text('¿Reemplazar clave maestra?'),
            content: const Text('Si reemplazás la clave existente, los APK que usan '
              'su clave pública anterior no aceptarán las nuevas licencias. '
              'Hacelo solo si sabés que estás restaurando la misma clave.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(dialog, true),
                child: const Text('Reemplazar')),
            ]));
        if (ok != true || !mounted) return;
      }
      await issuer.importMasterKey(bytes, replace: replacing);
      await refresh();
      if (mounted) setState(() => license = null);
      notify('Clave maestra restaurada.');
    } catch (e) {
      notify('Error al restaurar la clave: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final publicKey = key?['public'] as String?;
    return Scaffold(
      appBar: AppBar(title: const Text('Higea · Licencias')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(18),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Icon(Icons.vpn_key_outlined, size: 45),
              const SizedBox(height: 10),
              Text('Emisor privado offline',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              const Text('Generá pruebas gratuitas de 7 días o licencias comerciales permanentes. '
                'El comprador puede copiar y pegar la clave, sin tipearla.',
                textAlign: TextAlign.center),
              const SizedBox(height: 12),
              if (key == null)
                FilledButton.icon(onPressed: busy ? null : create,
                  icon: const Icon(Icons.add), label: const Text('Crear clave maestra'))
              else ...[
                const Text('Clave pública (para compilar Gym Lite):'),
                const SizedBox(height: 6),
                SelectableText(publicKey ?? ''),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: publicKey ?? ''));
                    notify('Clave pública copiada');
                  },
                  icon: const Icon(Icons.copy), label: const Text('Copiar clave pública')),
                const Divider(height: 26),
                const Text('Guardá la clave maestra fuera del teléfono. '
                  'Si lo perdés sin respaldo, no podrás emitir licencias de esta edición.',
                  style: TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: busy ? null : backup,
                  icon: const Icon(Icons.save_alt), label: const Text('Respaldar clave maestra')),
              ],
              OutlinedButton.icon(onPressed: busy ? null : restore,
                icon: const Icon(Icons.restore), label: const Text('Restaurar clave maestra')),
            ]),
          )),
          const SizedBox(height: 18),
          if (key != null) Card(child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Emitir licencia', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text('Tipo de licencia'),
              const SizedBox(height: 8),
              SegmentedButton<LicenseType>(
                segments: const [
                  ButtonSegment(value: LicenseType.trial,
                    label: Text('Prueba · 7 días'),
                    icon: Icon(Icons.hourglass_bottom)),
                  ButtonSegment(value: LicenseType.permanent,
                    label: Text('Comercial'),
                    icon: Icon(Icons.verified_outlined)),
                ],
                selected: {licenseType},
                onSelectionChanged: (selection) => setState(() {
                  licenseType = selection.first;
                  license = null;
                }),
              ),
              const SizedBox(height: 12),
              TextField(controller: controller, maxLength: 40, autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() => license = null),
                decoration: InputDecoration(
                  labelText: 'Código del cliente (8 caracteres)',
                  hintText: 'A4Y3-B7K2',
                  suffixIcon: IconButton(onPressed: pasteCode,
                    icon: const Icon(Icons.content_paste), tooltip: 'Pegar'),
                )),
              const SizedBox(height: 6),
              FilledButton.icon(onPressed: busy ? null : issue,
                icon: const Icon(Icons.verified_outlined),
                label: Text(licenseType == LicenseType.trial
                  ? 'Generar prueba gratuita' : 'Generar licencia permanente')),
              if (license != null) ...[
                const SizedBox(height: 18),
                Text(licenseType == LicenseType.trial
                  ? 'Prueba gratuita · 7 días desde la activación'
                  : 'Licencia comercial · permanente'),
                const SizedBox(height: 8),
                SelectableText(license!, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: license!));
                    notify('Licencia copiada');
                  },
                  icon: const Icon(Icons.copy), label: const Text('Copiar licencia')),
                FilledButton.icon(onPressed: shareLicense,
                  icon: const Icon(Icons.send), label: const Text('Enviar por WhatsApp u otra app')),
              ],
            ]),
          )),
          if (error != null) Padding(padding: const EdgeInsets.all(12),
            child: Text(error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 14),
          const Text('Esta herramienta no necesita Internet para crear licencias. '
            'Compartirlas por WhatsApp sí requiere conexión.',
            style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

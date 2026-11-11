import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'license_service.dart';

/// En release se exige licencia. En debug se puede probar con
/// --dart-define=REQUIRE_LICENSE=true.
const bool _debugRequireLicense = bool.fromEnvironment('REQUIRE_LICENSE', defaultValue: false);

class LicenseGate extends StatefulWidget {
  const LicenseGate({super.key, required this.child});
  final Widget child;
  @override
  State<LicenseGate> createState() => _LicenseGateState();
}

class _LicenseGateState extends State<LicenseGate> {
  // Se inicializa solo cuando la activación realmente se requiere.
  // Evita acceder al plugin nativo durante el modo debug y pruebas de widgets.
  late final LicenseService _service = LicenseService();
  final _field = TextEditingController();
  late Future<LicenseStatus> _status = _service.status();
  bool _saving = false;
  String? _message;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (_saving) return;
    setState(() { _saving = true; _message = null; });
    try {
      final ok = await _service.activate(_field.text);
      if (!mounted) return;
      setState(() {
        _message = ok ? null : 'Clave inválida para esta instalación.';
        _status = _service.status();
      });
    } catch (_) {
      if (mounted) setState(() {
        _message = 'No se pudo guardar la activación. Reintentá.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kReleaseMode && !_debugRequireLicense) return widget.child;
    return FutureBuilder<LicenseStatus>(
      future: _status,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child:
            Text('No se pudo verificar la licencia. No borres los datos de la app.')));
        }
        final status = snapshot.data!;
        if (status.valid) return widget.child;
        return Scaffold(
          body: SafeArea(child: Center(child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Icon(Icons.verified_user_outlined, size: 66,
                  color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 14),
                Text('Activar Gym Lite', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                const Text('La activación es permanente y funciona sin Internet. '
                  'Enviá este código al vendedor para solicitar la clave.',
                  textAlign: TextAlign.center),
                const SizedBox(height: 20),
                const Text('Código de esta instalación'),
                const SizedBox(height: 6),
                SelectableText(status.installationId.length == 8
                    ? status.installationId.substring(0, 4) + '-' +
                      status.installationId.substring(4)
                    : status.installationId,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800,
                    color: Colors.green.shade700,
                    fontSize: status.installationId.length == 8 ? 36 : 16,
                    letterSpacing: status.installationId.length == 8 ? 2 : 0)),
                TextButton.icon(
                  onPressed: () => Clipboard.setData(ClipboardData(text: status.installationId)),
                  icon: const Icon(Icons.copy), label: const Text('Copiar código'),
                ),
                TextButton.icon(
                  onPressed: () => SharePlus.instance.share(ShareParams(
                    text: 'Mi código para activar Gym Lite es:\n' +
                      status.installationId,
                    title: 'Solicitar licencia Gym Lite',
                  )),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Enviar código al vendedor'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _field, autocorrect: false, enableSuggestions: false,
                  decoration: InputDecoration(labelText: 'Clave de activación',
                    hintText: 'GSL1-...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste),
                      tooltip: 'Pegar licencia recibida',
                      onPressed: () async {
                        final copied = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
                        final match = RegExp(r'GSL1-[A-Za-z0-9_-]{86}').firstMatch(copied);
                        if (match != null) _field.text = match.group(0)!;
                      },
                    )), minLines: 1, maxLines: 3,
                ),
                if (_message != null) Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_message!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _activate,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(_saving ? 'Validando...' : 'Activar aplicación'),
                ),
                if (const String.fromEnvironment('GYM_LITE_PUBLIC_KEY').isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: Text('Esta versión no tiene una clave pública comercial configurada. '
                      'El desarrollador debe compilar un APK firmado.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.deepOrange)),
                  ),
                const SizedBox(height: 14),
                const Text('La licencia pertenece a esta instalación. '
                  'Al reinstalar o cambiar de celular puede requerirse otra clave. '
                  'Los respaldos de clientes no contienen licencias.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
              ])),
          ))),
        );
      },
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'seller_contact.dart';
import 'license_service.dart';

/// En release se exige licencia. En debug se puede probar con
/// --dart-define=REQUIRE_LICENSE=true.
const bool _debugRequireLicense = bool.fromEnvironment('REQUIRE_LICENSE', defaultValue: false);
// Solo en modo debug: permite probar la solicitud de licencia sin borrar datos.
const bool _debugPreviewActivation = bool.fromEnvironment('PREVIEW_ACTIVATION', defaultValue: false);

typedef TrialBackupCallback = Future<void> Function(BuildContext context);

class LicenseGate extends StatefulWidget {
  const LicenseGate({
    super.key,
    required this.child,
    this.onExportBackup,
  });
  final Widget child;
  final TrialBackupCallback? onExportBackup;

  @override
  State<LicenseGate> createState() => _LicenseGateState();
}

class _LicenseGateState extends State<LicenseGate> with WidgetsBindingObserver {
  // Se inicializa solo cuando la activación realmente se requiere.
  // Evita acceder al plugin nativo durante el modo debug y pruebas de widgets.
  late final LicenseService _service = LicenseService();
  final _field = TextEditingController();
  late Future<LicenseStatus> _status = _service.status();
  bool _saving = false;
  bool _exporting = false;
  bool _observingLifecycle = false;
  Timer? _trialTimer;
  String? _message;

  void _startTrialMonitoring() {
    if (_trialTimer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _observingLifecycle = true;
    _trialTimer = Timer.periodic(const Duration(minutes: 1), (_) => _refreshStatus());
  }

  void _stopTrialMonitoring() {
    _trialTimer?.cancel();
    _trialTimer = null;
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final updated = await _service.status();
      if (!mounted) return;
      setState(() => _status = Future.value(updated));
      if (!updated.isTrial || updated.trialExpired) _stopTrialMonitoring();
    } catch (_) {
      // Un error transitorio no borra ni modifica la licencia guardada.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  @override
  void dispose() {
    _stopTrialMonitoring();
    _field.dispose();
    super.dispose();
  }

  Future<void> _sendCodeToSeller(
    String installationId, {bool trialExpired = false}) async {
    try {
      final uri = SellerContact.activationRequest(
        installationId, trialExpired: trialExpired);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo abrir WhatsApp. Copiá el código y enviáselo al vendedor.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo abrir WhatsApp. Usá Copiar código para enviarlo manualmente.')));
      }
    }
  }

  Future<bool> _activate() async {
    if (_saving) return false;
    setState(() { _saving = true; _message = null; });
    try {
      final ok = await _service.activate(_field.text);
      final updated = await _service.status();
      if (!mounted) return false;
      setState(() {
        _message = ok ? null : 'Clave inválida para esta instalación o tipo de licencia.';
        _status = Future.value(updated);
      });
      if (updated.isPermanent) _stopTrialMonitoring();
      return ok && updated.isPermanent;
    } catch (_) {
      if (mounted) setState(() {
        _message = 'No se pudo guardar la activación. Reintentá.';
      });
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showCommercialActivation() async {
    _field.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) => AlertDialog(
          title: const Text('Activar licencia comercial'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Pegá la licencia permanente que te envió el vendedor. '
              'La prueba y todos tus datos se conservarán.'),
            const SizedBox(height: 12),
            TextField(
              controller: _field,
              autocorrect: false,
              enableSuggestions: false,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Licencia comercial',
                hintText: 'GSL2-P-...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  tooltip: 'Pegar licencia',
                  onPressed: () async {
                    final copied = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
                    final match = RegExp(r'(?:GSL2-P|GSL2-T|GSL1)-[A-Za-z0-9_-]{86}')
                        .firstMatch(copied);
                    if (match != null) {
                      _field.text = match.group(0)!;
                      refresh(() {});
                    }
                  },
                ),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 8),
              Text(_message!, style: const TextStyle(color: Colors.red)),
            ],
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: _saving ? null : () async {
                final activated = await _activate();
                if (activated && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                } else {
                  refresh(() {});
                }
              },
              child: Text(_saving ? 'Validando...' : 'Activar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    final callback = widget.onExportBackup;
    if (callback == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      await callback(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo exportar el respaldo: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kReleaseMode && !_debugRequireLicense && !_debugPreviewActivation) return widget.child;
    return FutureBuilder<LicenseStatus>(
      future: _status,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF11243B),
            body: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF36A676),
                  child: Icon(Icons.fitness_center, color: Colors.white, size: 42),
                ),
                SizedBox(height: 20),
                Text('Higea Fitness',
                    style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 24)),
                SizedBox(height: 18),
                SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2,
                    color: Color(0xFF36A676))),
              ],
            )),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child:
            Text('No se pudo verificar la licencia. No borres los datos de la app.')));
        }
        final status = snapshot.data!;

        if (status.valid && (kReleaseMode || !_debugPreviewActivation)) {
          if (!status.isTrial) return widget.child;
          _startTrialMonitoring();
          return Stack(children: [
            widget.child,
            Positioned(
              left: 12, right: 12, bottom: 84,
              child: SafeArea(top: false, child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(children: [
                    const Icon(Icons.hourglass_bottom, color: Color(0xFF36A676)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Prueba gratuita',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(status.trialDaysRemaining == 1 ? 'Queda 1 día' : 'Quedan ${status.trialDaysRemaining} días',
                          style: Theme.of(context).textTheme.bodySmall),
                      ],
                    )),
                    TextButton(
                      onPressed: _showCommercialActivation,
                      child: const Text('Activar compra'),
                    ),
                  ]),
                ),
              )),
            ),
          ]);
        }

        final expiredTrial = status.trialExpired;
        return Scaffold(
          body: SafeArea(child: Center(child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Icon(expiredTrial ? Icons.hourglass_disabled : Icons.verified_user_outlined,
                  size: 66, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 14),
                Text(expiredTrial ? 'Tu prueba gratuita finalizó' : 'Activar Higea Fitness',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(expiredTrial
                  ? 'Los 7 días de prueba terminaron. Tus clientes, pagos y configuraciones '
                    'siguen guardados en este teléfono. Ingresá tu licencia comercial para '
                    'continuar usando Higea.'
                  : 'La activación funciona sin Internet. Podés solicitar una prueba gratuita '
                    'de 7 días o activar una licencia comercial permanente. Enviá este código '
                    'al vendedor para recibir tu clave.',
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
                  onPressed: () => _sendCodeToSeller(
                    status.installationId, trialExpired: expiredTrial),
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Enviar código al vendedor'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _field, autocorrect: false, enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: expiredTrial ? 'Licencia comercial' : 'Clave de activación',
                    hintText: 'GSL2-...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste),
                      tooltip: 'Pegar licencia recibida',
                      onPressed: () async {
                        final copied = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
                        final match = RegExp(r'(?:GSL2-P|GSL2-T|GSL1)-[A-Za-z0-9_-]{86}')
                            .firstMatch(copied);
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
                  label: Text(_saving ? 'Validando...' :
                    expiredTrial ? 'Activar licencia comercial' : 'Activar aplicación'),
                ),
                if (expiredTrial && widget.onExportBackup != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : _exportBackup,
                    icon: const Icon(Icons.save_alt_outlined),
                    label: Text(_exporting ? 'Preparando respaldo...' : 'Guardar respaldo cifrado'),
                  ),
                ],
                if (const String.fromEnvironment('GYM_LITE_PUBLIC_KEY').isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: Text('Esta versión no tiene una clave pública comercial configurada. '
                      'El desarrollador debe compilar un APK firmado.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.deepOrange)),
                  ),
                const SizedBox(height: 14),
                Text(expiredTrial
                  ? 'La prueba no se reinicia al volver a introducir su clave. '
                    'La licencia comercial activa esta misma instalación sin borrar datos.'
                  : 'La licencia pertenece a esta instalación. Al reinstalar o cambiar de '
                    'celular puede requerirse otra clave. Los respaldos no contienen licencias.',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              ])),
          ))),
        );
      },
    );
  }
}

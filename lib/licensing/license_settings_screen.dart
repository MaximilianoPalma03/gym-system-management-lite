import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'license_service.dart';
import 'seller_contact.dart';

/// La administración de licencias es accesible desde Ajustes durante
/// una prueba vigente o con una licencia permanente.
class LicenseSettingsScreen extends StatefulWidget {
  const LicenseSettingsScreen({super.key, this.service});

  /// Permite probar la pantalla sin acceder a las preferencias del dispositivo.
  final LicenseService? service;

  @override
  State<LicenseSettingsScreen> createState() => _LicenseSettingsScreenState();
}

class _LicenseSettingsScreenState extends State<LicenseSettingsScreen> {
  late final LicenseService _service = widget.service ?? LicenseService();
  late Future<LicenseStatus> _status = _service.status();
  final _licenseController = TextEditingController();
  bool _activating = false;
  String? _error;

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() => _status = _service.status());
  }

  Future<void> _activateCommercial() async {
    if (_activating) return;
    setState(() {
      _activating = true;
      _error = null;
    });
    try {
      final valid = await _service.activate(_licenseController.text);
      if (!mounted) return;
      final updated = await _service.status();
      if (!mounted) return;
      setState(() {
        _status = Future.value(updated);
        if (!valid || !updated.isPermanent) {
          _error = 'La licencia comercial no es válida para esta instalación.';
        } else {
          _licenseController.clear();
        }
      });
      if (valid && updated.isPermanent) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Higea Fitness está activado permanentemente.')));
      }
    } catch (_) {
      if (mounted) setState(() =>
        _error = 'No se pudo completar la activación. Reintentá.');
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  Future<void> _sendCode(String id) async {
    try {
      final launched = await launchUrl(
        SellerContact.activationRequest(id),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo abrir WhatsApp. Copiá el código y envialo al vendedor.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo abrir WhatsApp. Copiá el código y envialo al vendedor.')));
      }
    }
  }

  Future<void> _paste() async {
    final copied = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (!mounted) return;
    final match = RegExp(r'(?:GSL2-P|GSL1)-[A-Za-z0-9_-]{86}')
        .firstMatch(copied);
    if (match != null) {
      _licenseController.text = match.group(0)!;
      setState(() => _error = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Licencia de Higea Fitness')),
    body: FutureBuilder<LicenseStatus>(
      future: _status,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('No se pudo leer la licencia. No borres los datos.'),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _refresh, child: const Text('Reintentar')),
            ]),
          ));
        }
        final status = snapshot.data!;
        final isTrial = status.isTrial && status.valid;
        final isPermanent = status.isPermanent;
        final id = status.installationId;
        final displayId = id.length == 8
            ? '${id.substring(0, 4)}-${id.substring(4)}' : id;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(isPermanent ? Icons.verified : isTrial
                        ? Icons.hourglass_top : Icons.info_outline),
                    const SizedBox(width: 10),
                    Expanded(child: Text(isPermanent ? 'Licencia comercial activa'
                        : isTrial ? 'Prueba gratuita activa'
                        : status.trialExpired ? 'Prueba finalizada'
                        : 'Sin licencia activa',
                      style: Theme.of(context).textTheme.titleMedium)),
                  ]),
                  const SizedBox(height: 12),
                  Text(isPermanent
                      ? 'Higea está activado permanentemente en este dispositivo.'
                      : isTrial
                          ? 'Queda${status.trialDaysRemaining == 1 ? '' : 'n'} '
                            '${status.trialDaysRemaining} '
                            'día${status.trialDaysRemaining == 1 ? '' : 's'} '
                            'de prueba. Podés comprar la licencia en cualquier momento.'
                          : 'Necesitás una licencia comercial para continuar usando Higea.'),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Text('Código de instalación',
              style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(displayId),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              OutlinedButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: id)),
                icon: const Icon(Icons.copy),
                label: const Text('Copiar código'),
              ),
              if (!isPermanent)
                OutlinedButton.icon(
                  onPressed: () => _sendCode(id),
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Solicitar licencia'),
                ),
            ]),
            if (!isPermanent) ...[
              const SizedBox(height: 24),
              Text('Activar licencia comercial',
                style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text('Pegá la clave permanente enviada por el vendedor. '
                'Tus clientes, pagos y configuraciones se conservan.'),
              const SizedBox(height: 12),
              TextField(
                controller: _licenseController,
                autocorrect: false,
                enableSuggestions: false,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Clave comercial',
                  hintText: 'GSL2-P-...',
                  suffixIcon: IconButton(
                    onPressed: _paste,
                    tooltip: 'Pegar clave',
                    icon: const Icon(Icons.content_paste),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(
                  color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _activating ? null : _activateCommercial,
                icon: const Icon(Icons.verified_outlined),
                label: Text(_activating ? 'Activando...' : 'Activar compra'),
              ),
            ],
          ],
        );
      },
    ),
  );

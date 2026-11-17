import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../services/backup_service.dart';
import '../state/gym_store.dart';

/// Permite al usuario conservar sus datos si deja vencer la prueba gratuita.
class TrialBackupExporter {
  const TrialBackupExporter._();

  static Future<void> export(BuildContext context, GymStore store) async {
    final password = await _askPassword(context);
    if (!context.mounted || password == null) return;
    try {
      final bytes = await BackupService(store.repo).exportEncrypted(password);
      final filename = 'higea-respaldo-' + dateKey(DateTime.now()) + '.gymlite';
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar respaldo protegido de Higea',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['gymlite'],
        bytes: bytes,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(saved == null
            ? 'Guardado cancelado.'
            : 'Respaldo exportado. Conservá la contraseña para recuperarlo.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo exportar el respaldo: $e')));
      }
    }
  }

  static Future<String?> _askPassword(BuildContext context) async {
    var password = '';
    var repeated = '';
    return showDialog<String>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, refresh) => AlertDialog(
          title: const Text('Guardar respaldo cifrado'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Elegí una contraseña de al menos 8 caracteres. '
              'La necesitarás para recuperar los datos en Higea.'),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              onChanged: (value) => refresh(() => password = value),
            ),
            const SizedBox(height: 10),
            TextField(
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'Repetir contraseña'),
              onChanged: (value) => refresh(() => repeated = value),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: password.length >= 8 && repeated == password
                ? () => Navigator.pop(dialog, password) : null,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

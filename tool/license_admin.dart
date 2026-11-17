// Herramienta de uso exclusivo del desarrollador. Nunca subir la privada.
// dart run tool/license_admin.dart init "C:\ruta\fuera\repo\clave.json"
// dart run tool/license_admin.dart issue "C:\ruta\clave.json" 0123ABCDEF...
import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  if (args.length < 2 || !['init', 'issue'].contains(args[0])) {
    stderr.writeln('Uso: dart run tool/license_admin.dart init <ruta-privada>');
    stderr.writeln('     dart run tool/license_admin.dart issue <ruta-privada> <codigo-instalacion>');
    exitCode = 64;
    return;
  }
  final file = File(args[1]);
  final algorithm = Ed25519();
  if (args[0] == 'init') {
    if (file.existsSync()) {
      stderr.writeln('La clave ya existe. Nunca la sobrescribas.');
      exitCode = 1;
      return;
    }
    await file.parent.create(recursive: true);
    final keyPair = await algorithm.newKeyPair();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    await file.writeAsString(jsonEncode({
      'format': 'gym-lite-ed25519-v1',
      'private': base64Url.encode(privateBytes),
      'public': base64Url.encode(publicKey.bytes),
    }), flush: true);
    stdout.writeln('CLAVE PRIVADA: ' + file.absolute.path);
    stdout.writeln('NO SUBIR NI COMPARTIR ESTA CLAVE. RESPALDALA EN LUGAR SEGURO.');
    stdout.writeln('CLAVE PÚBLICA PARA COMPILAR: ' + base64Url.encode(publicKey.bytes));
    keyPair.destroy();
    return;
  }
  if (args.length != 3) {
    stderr.writeln('Falta el código de instalación del cliente.');
    exitCode = 64;
    return;
  }
  final id = args[2].trim().toUpperCase();
  if (!(RegExp(r'^[A-HJ-NP-Z2-9]{8}$').hasMatch(id) ||
        RegExp(r'^[A-F0-9]{32}$').hasMatch(id))) {
    stderr.writeln('El código debe tener 8 caracteres alfanuméricos (o 32 de una instalación anterior).');
    exitCode = 64;
    return;
  }
  final secret = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  if (secret['format'] != 'gym-lite-ed25519-v1') {
    throw const FormatException('Archivo de clave no compatible.');
  }
  final keyPair = SimpleKeyPairData(
    base64Url.decode(base64Url.normalize(secret['private'] as String)),
    publicKey: SimplePublicKey(
      base64Url.decode(base64Url.normalize(secret['public'] as String)),
      type: KeyPairType.ed25519,
    ),
    type: KeyPairType.ed25519,
  );
  try {
    final signature = await algorithm.sign(
      utf8.encode('GSL1|' + id), keyPair: keyPair);
    stdout.writeln('CLAVE PARA ESTA INSTALACIÓN:');
    stdout.writeln('GSL1-' + base64Url.encode(signature.bytes).replaceAll('=', ''));
  } finally {
    keyPair.destroy();
  }
}

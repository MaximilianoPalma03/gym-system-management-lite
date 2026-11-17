import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LicenseType { trial, permanent }

class LicenseIssuer {
  LicenseIssuer({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _prefs;
  static const storageKey = 'gym_lite_private_issuer_v1';
  final algorithm = Ed25519();

  static String normalizeInstallationCode(String value) =>
    value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  static bool isValidInstallationCode(String value) =>
    RegExp(r'^[A-HJ-NP-Z2-9]{8}$').hasMatch(normalizeInstallationCode(value)) ||
    RegExp(r'^[A-F0-9]{32}$').hasMatch(normalizeInstallationCode(value));

  Future<String?> rawKey() => _prefs.getString(storageKey);

  Future<Map<String, dynamic>?> storedKey() async {
    final value = await rawKey();
    if (value == null) return null;
    return jsonDecode(value) as Map<String, dynamic>;
  }

  Future<String> createKey() async {
    if (await rawKey() != null) throw StateError('Ya existe una clave maestra en este celular.');
    final pair = await algorithm.newKeyPair();
    try {
      final privateBytes = await pair.extractPrivateKeyBytes();
      final public = await pair.extractPublicKey();
      final payload = jsonEncode({
        'format': 'gym-lite-ed25519-v1',
        'private': base64Url.encode(privateBytes),
        'public': base64Url.encode(public.bytes),
      });
      await _prefs.setString(storageKey, payload);
      return base64Url.encode(public.bytes);
    } finally {
      pair.destroy();
    }
  }

  static Future<bool> validateKey(Map<String, dynamic> key) async {
    try {
      if (key['format'] != 'gym-lite-ed25519-v1') return false;
      final privateBytes = base64Url.decode(base64Url.normalize(key['private'] as String));
      final publicBytes = base64Url.decode(base64Url.normalize(key['public'] as String));
      if (privateBytes.length != 32 || publicBytes.length != 32) return false;
      final pair = SimpleKeyPairData(privateBytes,
        publicKey: SimplePublicKey(publicBytes, type: KeyPairType.ed25519),
        type: KeyPairType.ed25519);
      try {
        final signature = await Ed25519().sign(utf8.encode('self-check'), keyPair: pair);
        return await Ed25519().verify(
          utf8.encode('self-check'), signature: signature);
      } finally {
        pair.destroy();
      }
    } catch (_) {
      return false;
    }
  }

  Future<String> issue(String code, {
    LicenseType type = LicenseType.permanent,
  }) async {
    final id = normalizeInstallationCode(code);
    if (!isValidInstallationCode(id)) throw ArgumentError('Código de instalación inválido.');
    final data = await storedKey();
    if (data == null || !await validateKey(data)) {
      throw StateError('La clave maestra no está disponible o es inválida.');
    }
    final privateBytes = base64Url.decode(base64Url.normalize(data['private'] as String));
    final publicBytes = base64Url.decode(base64Url.normalize(data['public'] as String));
    final pair = SimpleKeyPairData(privateBytes,
      publicKey: SimplePublicKey(publicBytes, type: KeyPairType.ed25519),
      type: KeyPairType.ed25519);
    try {
      final isTrial = type == LicenseType.trial;
      final message = 'GSL2|${isTrial ? 'trial' : 'permanent'}|$id';
      final signature = await algorithm.sign(utf8.encode(message), keyPair: pair);
      final prefix = isTrial ? 'GSL2-T-' : 'GSL2-P-';
      return '$prefix${base64Url.encode(signature.bytes).replaceAll('=', '')}';
    } finally {
      pair.destroy();
    }
  }

  Future<Uint8List> exportMasterKey() async {
    final raw = await rawKey();
    if (raw == null) throw StateError('No hay clave maestra todavía.');
    return Uint8List.fromList(utf8.encode(raw));
  }

  Future<void> importMasterKey(Uint8List bytes, {bool replace = false}) async {
    if (bytes.length > 4096) throw const FormatException('Archivo de clave demasiado grande.');
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! Map<String, dynamic> || !await validateKey(data)) {
      throw const FormatException('Archivo de clave no válido.');
    }
    if (!replace && await rawKey() != null) {
      throw StateError('Ya existe una clave maestra. Debés confirmar el reemplazo.');
    }
    await _prefs.setString(storageKey, jsonEncode(data));
  }
}

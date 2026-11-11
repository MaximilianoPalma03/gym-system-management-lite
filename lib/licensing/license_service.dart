import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clave pública en el APK mediante --dart-define. Nunca incluir la privada.
const String _publicKeyBase64 = String.fromEnvironment('GYM_LITE_PUBLIC_KEY');

class LicenseStatus {
  const LicenseStatus({required this.installationId, required this.valid});
  final String installationId;
  final bool valid;
}

class LicenseService {
  LicenseService({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  static const _installationKey = 'gym_lite_installation_v1';
  static const _licenseKey = 'gym_lite_license_v1';

  Future<String> installationId() async {
    final existing = await _preferences.getString(_installationKey);
    if (existing != null && RegExp(r'^[A-HJ-NP-Z2-9]{8}$').hasMatch(existing)) {
      return existing;
    }
    // Mantener instalaciones anteriores ya activadas sin invalidar sus claves.
    if (existing != null && RegExp(r'^[A-F0-9]{32}$').hasMatch(existing) &&
        await _preferences.getString(_licenseKey) != null) {
      return existing;
    }
    const symbols = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final id = List.generate(8, (_) => symbols[random.nextInt(symbols.length)]).join();
    await _preferences.setString(_installationKey, id);
    return id;
  }

  Future<LicenseStatus> status() async {
    final id = await installationId();
    final saved = await _preferences.getString(_licenseKey);
    return LicenseStatus(
      installationId: id,
      valid: saved != null && await verifyLicense(
        publicKeyBase64: _publicKeyBase64,
        installationId: id,
        license: saved,
      ),
    );
  }

  Future<bool> activate(String code) async {
    final id = await installationId();
    final normalized = code.trim();
    final valid = await verifyLicense(
      publicKeyBase64: _publicKeyBase64, installationId: id,
      license: normalized,
    );
    if (!valid) return false;
    await _preferences.setString(_licenseKey, normalized);
    return true;
  }

  static Future<bool> verifyLicense({
    required String publicKeyBase64,
    required String installationId,
    required String license,
  }) async {
    try {
      if (publicKeyBase64.isEmpty ||
          !(RegExp(r'^[A-HJ-NP-Z2-9]{8}$').hasMatch(installationId) ||
            RegExp(r'^[A-F0-9]{32}$').hasMatch(installationId))) {
        return false;
      }
      final match = RegExp(r'^GSL1-([A-Za-z0-9_-]{86})={0,2}$').firstMatch(license.trim());
      if (match == null) return false;
      final publicBytes = base64Url.decode(base64Url.normalize(publicKeyBase64));
      final signatureBytes = base64Url.decode(base64Url.normalize(match.group(1)!));
      if (publicBytes.length != 32 || signatureBytes.length != 64) return false;
      final signature = Signature(signatureBytes,
        publicKey: SimplePublicKey(publicBytes, type: KeyPairType.ed25519));
      return await Ed25519().verify(
        utf8.encode('GSL1|' + installationId),
        signature: signature,
      );
    } catch (_) {
      return false;
    }
  }
}

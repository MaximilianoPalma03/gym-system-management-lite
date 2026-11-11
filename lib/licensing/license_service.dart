import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clave pública incluida en el APK comercial. Nunca incluir la privada.
const String _defaultPublicKeyBase64 = String.fromEnvironment('GYM_LITE_PUBLIC_KEY');

enum LicenseKind { none, trial, permanent }

class LicenseStatus {
  const LicenseStatus({
    required this.installationId,
    required this.valid,
    this.kind = LicenseKind.none,
    this.trialExpiresAt,
    this.trialDaysRemaining = 0,
  });

  final String installationId;
  final bool valid;
  final LicenseKind kind;
  final DateTime? trialExpiresAt;
  final int trialDaysRemaining;

  bool get isTrial => kind == LicenseKind.trial;
  bool get trialExpired => isTrial && !valid;
  bool get isPermanent => kind == LicenseKind.permanent && valid;
}

class LicenseService {
  LicenseService({
    SharedPreferencesAsync? preferences,
    String? publicKeyBase64,
    DateTime Function()? clock,
  })  : _preferences = preferences ?? SharedPreferencesAsync(),
        _publicKeyBase64 = publicKeyBase64 ?? _defaultPublicKeyBase64,
        _clock = clock ?? DateTime.now;

  final SharedPreferencesAsync _preferences;
  final String _publicKeyBase64;
  final DateTime Function() _clock;

  static const _installationKey = 'gym_lite_installation_v1';
  static const _licenseKey = 'gym_lite_license_v1';
  static const _trialStartedKey = 'gym_lite_trial_started_at_v1';
  static const _permanentActivatedKey = 'gym_lite_permanent_activated_v1';
  static const trialDuration = Duration(days: 7);

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
    if (saved == null) {
      return LicenseStatus(installationId: id, valid: false);
    }

    final kind = await _verifiedKind(
      publicKeyBase64: _publicKeyBase64,
      installationId: id,
      license: saved,
    );
    if (kind == null) {
      return LicenseStatus(installationId: id, valid: false);
    }
    if (kind == LicenseKind.permanent) {
      return LicenseStatus(
        installationId: id, valid: true, kind: LicenseKind.permanent);
    }

    // La fecha de inicio se guarda una sola vez, al activar la prueba.
    // Volver a introducir la misma clave no reinicia los siete días.
    var startedAt = await _preferences.getInt(_trialStartedKey);
    if (startedAt == null) {
      startedAt = _clock().toUtc().millisecondsSinceEpoch;
      await _preferences.setInt(_trialStartedKey, startedAt);
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      startedAt, isUtc: true).add(trialDuration);
    final now = _clock().toUtc();
    final remaining = expiresAt.difference(now);
    final active = remaining.inSeconds > 0;
    final daysRemaining = active
        ? (remaining.inSeconds + const Duration(days: 1).inSeconds - 1) ~/
            const Duration(days: 1).inSeconds
        : 0;
    return LicenseStatus(
      installationId: id,
      valid: active,
      kind: LicenseKind.trial,
      trialExpiresAt: expiresAt,
      trialDaysRemaining: daysRemaining,
    );
  }

  Future<bool> activate(String code) async {
    final id = await installationId();
    final normalized = code.trim();
    final kind = await _verifiedKind(
      publicKeyBase64: _publicKeyBase64,
      installationId: id,
      license: normalized,
    );
    if (kind == null) return false;

    final existing = await _preferences.getString(_licenseKey);
    final existingKind = existing == null ? null : await _verifiedKind(
      publicKeyBase64: _publicKeyBase64,
      installationId: id,
      license: existing,
    );

    if (kind == LicenseKind.trial) {
      final permanentActivated =
          await _preferences.getBool(_permanentActivatedKey) ?? false;
      if (permanentActivated || existingKind == LicenseKind.permanent) {
        return false;
      }
      final previousTrialStart = await _preferences.getInt(_trialStartedKey);
      if (previousTrialStart != null) {
        // Permite reintentar la misma clave mientras siga vigente, sin reiniciar
        // el plazo. Una prueba vencida nunca se reactiva con otra clave de prueba.
        if (existingKind != LicenseKind.trial || existing != normalized) return false;
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(
          previousTrialStart, isUtc: true).add(trialDuration);
        return _clock().toUtc().isBefore(expiresAt);
      }
      await _preferences.setString(_licenseKey, normalized);
      await _preferences.setInt(
        _trialStartedKey, _clock().toUtc().millisecondsSinceEpoch);
      return true;
    }

    // Una licencia permanente convierte la prueba en compra sin reinstalar
    // ni modificar la base de datos local.
    await _preferences.setString(_licenseKey, normalized);
    await _preferences.setBool(_permanentActivatedKey, true);
    return true;
  }

  static Future<LicenseKind?> _verifiedKind({
    required String publicKeyBase64,
    required String installationId,
    required String license,
  }) async {
    try {
      if (publicKeyBase64.isEmpty ||
          !(RegExp(r'^[A-HJ-NP-Z2-9]{8}$').hasMatch(installationId) ||
            RegExp(r'^[A-F0-9]{32}$').hasMatch(installationId))) {
        return null;
      }

      String message;
      LicenseKind kind;
      String encodedSignature;

      final legacy = RegExp(r'^GSL1-([A-Za-z0-9_-]{86})={0,2}$')
          .firstMatch(license.trim());
      if (legacy != null) {
        // Compatibilidad: todas las licencias GSL1 existentes son permanentes.
        message = 'GSL1|' + installationId;
        kind = LicenseKind.permanent;
        encodedSignature = legacy.group(1)!;
      } else {
        final current = RegExp(r'^GSL2-([TP])-([A-Za-z0-9_-]{86})={0,2}$')
            .firstMatch(license.trim());
        if (current == null) return null;
        kind = current.group(1) == 'T'
            ? LicenseKind.trial : LicenseKind.permanent;
        final type = kind == LicenseKind.trial ? 'trial' : 'permanent';
        message = 'GSL2|' + type + '|' + installationId;
        encodedSignature = current.group(2)!;
      }

      final publicBytes = base64Url.decode(base64Url.normalize(publicKeyBase64));
      final signatureBytes = base64Url.decode(base64Url.normalize(encodedSignature));
      if (publicBytes.length != 32 || signatureBytes.length != 64) return null;
      final signature = Signature(signatureBytes,
        publicKey: SimplePublicKey(publicBytes, type: KeyPairType.ed25519));
      final valid = await Ed25519().verify(
        utf8.encode(message), signature: signature);
      return valid ? kind : null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> verifyLicense({
    required String publicKeyBase64,
    required String installationId,
    required String license,
  }) async =>
      await _verifiedKind(
        publicKeyBase64: publicKeyBase64,
        installationId: installationId,
        license: license,
      ) != null;
}

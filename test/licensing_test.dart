import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:gym_system_management_lite/licensing/license_service.dart';

const installation = 'A4Y3B7K2';

Future<String> signLicense(
  Ed25519 algorithm, KeyPair pair, String type, String id) async {
  final message = type == 'legacy'
      ? 'GSL1|' + id
      : 'GSL2|' + type + '|' + id;
  final signature = await algorithm.sign(utf8.encode(message), keyPair: pair);
  if (type == 'legacy') {
    return 'GSL1-' + base64Url.encode(signature.bytes).replaceAll('=', '');
  }
  final prefix = type == 'trial' ? 'GSL2-T-' : 'GSL2-P-';
  return prefix + base64Url.encode(signature.bytes).replaceAll('=', '');
}

void main() {
  late Ed25519 algorithm;
  late KeyPair pair;
  late String publicKey;
  late String trialLicense;
  late String permanentLicense;
  late String legacyLicense;
  late DateTime now;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    algorithm = Ed25519();
    pair = await algorithm.newKeyPair();
    final extractedPublicKey = await pair.extractPublicKey();
    if (extractedPublicKey is! SimplePublicKey) {
      throw StateError('Ed25519 devolvió una clave pública incompatible.');
    }
    publicKey = base64Url.encode(extractedPublicKey.bytes);
    trialLicense = await signLicense(algorithm, pair, 'trial', installation);
    permanentLicense = await signLicense(algorithm, pair, 'permanent', installation);
    legacyLicense = await signLicense(algorithm, pair, 'legacy', installation);
    now = DateTime.utc(2026, 11, 11, 12);
  });

  test('La licencia queda vinculada al código de una sola instalación', () async {
    const other = 'B4Y3B7K2';
    expect(await LicenseService.verifyLicense(
      publicKeyBase64: publicKey,
      installationId: installation,
      license: permanentLicense), true);
    expect(await LicenseService.verifyLicense(
      publicKeyBase64: publicKey,
      installationId: other,
      license: permanentLicense), false);
    expect(await LicenseService.verifyLicense(
      publicKeyBase64: publicKey,
      installationId: installation,
      license: 'GSL2-P-invalid'), false);
  });

  test('La prueba empieza al activarse y vence exactamente a los siete días', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString('gym_lite_installation_v1', installation);
    final service = LicenseService(
      preferences: preferences,
      publicKeyBase64: publicKey,
      clock: () => now,
    );

    expect((await service.status()).kind, LicenseKind.none);
    expect(await service.activate(trialLicense), true);
    var status = await service.status();
    expect(status.valid, true);
    expect(status.isTrial, true);
    expect(status.trialDaysRemaining, 7);

    now = now.add(const Duration(days: 2));
    expect(await service.activate(trialLicense), true);
    status = await service.status();
    expect(status.valid, true);
    expect(status.trialDaysRemaining, 5);

    now = now.add(const Duration(days: 5));
    status = await service.status();
    expect(status.valid, false);
    expect(status.trialExpired, true);
    expect(status.trialDaysRemaining, 0);
    expect(await service.activate(trialLicense), false);
  });

  test('Una licencia permanente convierte la prueba sin reinstalar', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString('gym_lite_installation_v1', installation);
    final service = LicenseService(
      preferences: preferences,
      publicKeyBase64: publicKey,
      clock: () => now,
    );

    expect(await service.activate(trialLicense), true);
    now = now.add(const Duration(days: 8));
    expect((await service.status()).trialExpired, true);
    expect(await service.activate(permanentLicense), true);

    final status = await service.status();
    expect(status.valid, true);
    expect(status.isPermanent, true);
    expect(status.installationId, installation);

    now = now.add(const Duration(days: 365));
    expect((await service.status()).valid, true);
    expect(await service.activate(trialLicense), false);
  });

  test('Las licencias permanentes GSL1 anteriores siguen siendo válidas', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString('gym_lite_installation_v1', installation);
    final service = LicenseService(
      preferences: preferences,
      publicKeyBase64: publicKey,
      clock: () => now,
    );
    expect(await service.activate(legacyLicense), true);
    final status = await service.status();
    expect(status.isPermanent, true);
    expect(status.valid, true);
  });
}

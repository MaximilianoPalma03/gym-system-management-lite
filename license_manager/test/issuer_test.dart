import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:gym_lite_license_manager/license_issuer.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('La clave maestra es Ed25519 y puede validarse', () async {
    final algorithm = Ed25519();
    final pair = await algorithm.newKeyPair();
    final privateBytes = await pair.extractPrivateKeyBytes();
    final extractedPublicKey = await pair.extractPublicKey();
    expect(extractedPublicKey, isA<SimplePublicKey>());
    final publicKey = extractedPublicKey as SimplePublicKey;
    final payload = {
      'format': 'gym-lite-ed25519-v1',
      'private': base64Url.encode(privateBytes),
      'public': base64Url.encode(publicKey.bytes),
    };
    expect(await LicenseIssuer.validateKey(payload), true);
    pair.destroy();
  });

  test('Emite una clave de prueba de siete días y una permanente', () async {
    final issuer = LicenseIssuer();
    await issuer.createKey();
    final trial = await issuer.issue('A4Y3-B7K2', type: LicenseType.trial);
    final permanent = await issuer.issue('A4Y3-B7K2', type: LicenseType.permanent);
    expect(trial, startsWith('GSL2-T-'));
    expect(permanent, startsWith('GSL2-P-'));
    expect(trial.length, 93);
    expect(permanent.length, 93);

    final key = await issuer.storedKey();
    final publicBytes = base64Url.decode(base64Url.normalize(key!['public'] as String));
    final public = SimplePublicKey(publicBytes, type: KeyPairType.ed25519);
    for (final item in [
      (trial, 'trial'),
      (permanent, 'permanent'),
    ]) {
      final match = RegExp(r'^GSL2-[TP]-([A-Za-z0-9_-]{86})$').firstMatch(item.$1)!;
      final signature = Signature(
        base64Url.decode(base64Url.normalize(match.group(1)!)),
        publicKey: public,
      );
      expect(await Ed25519().verify(
        utf8.encode('GSL2|' + item.$2 + '|A4Y3B7K2'),
        signature: signature,
      ), true);
    }
    expect(trial, isNot(permanent));
  });

  test('No admite IDs inválidos y normaliza el formato visual', () {
    expect(LicenseIssuer.isValidInstallationCode('0123456789ABCDEF0123456789ABCDEF'), true);
    expect(LicenseIssuer.isValidInstallationCode('ABCD'), false);
    expect(LicenseIssuer.isValidInstallationCode('A4Y3-B7K2'), true);
    expect(LicenseIssuer.normalizeInstallationCode('a4y3-b7k2'), 'A4Y3B7K2');
  });
}

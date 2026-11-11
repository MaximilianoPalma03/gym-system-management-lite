import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system_management_lite/licensing/license_service.dart';

void main() {
  test('La clave Ed25519 solo sirve para la instalación autorizada', () async {
    const original = '0123456789ABCDEF0123456789ABCDEF';
    const other = 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF';
    final algorithm = Ed25519();
    final pair = await algorithm.newKeyPair();
    final publicKey = await pair.extractPublicKey();
    final signature = await algorithm.sign(
      utf8.encode('GSL1|' + original), keyPair: pair);
    final license = 'GSL1-' + base64Url.encode(signature.bytes).replaceAll('=', '');
    final encodedPublic = base64Url.encode(publicKey.bytes);
    expect(await LicenseService.verifyLicense(
      publicKeyBase64: encodedPublic, installationId: original,
      license: license), true);
    expect(await LicenseService.verifyLicense(
      publicKeyBase64: encodedPublic, installationId: other,
      license: license), false);
    expect(await LicenseService.verifyLicense(
      publicKeyBase64: encodedPublic, installationId: original,
      license: 'GSL1-invalid'), false);
    pair.destroy();
  });
}

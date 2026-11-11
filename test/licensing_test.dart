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
  test('La clave de una instalación corta no activa otra instalación', () async {
    const first = 'A4Y3B7K2';
    const second = 'B4Y3B7K2';
    final alg = Ed25519();
    final keys = await alg.newKeyPair();
    final pub = await keys.extractPublicKey();
    final signature = await alg.sign(utf8.encode('GSL1|' + first), keyPair: keys);
    final code = 'GSL1-' + base64Url.encode(signature.bytes).replaceAll('=', '');
    final public = base64Url.encode(pub.bytes);
    expect(await LicenseService.verifyLicense(
      publicKeyBase64: public, installationId: first, license: code), true);
    expect(await LicenseService.verifyLicense(
      publicKeyBase64: public, installationId: second, license: code), false);
    keys.destroy();
  });

}

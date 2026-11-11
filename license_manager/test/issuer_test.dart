import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_lite_license_manager/license_issuer.dart';

void main() {
  test('La clave maestra es Ed25519 y la firma coincide con el formato del cliente', () async {
    final algorithm = Ed25519();
    final pair = await algorithm.newKeyPair();
    final privateBytes = await pair.extractPrivateKeyBytes();
    final publicKey = await pair.extractPublicKey();
    final payload = {
      'format': 'gym-lite-ed25519-v1',
      'private': base64Url.encode(privateBytes),
      'public': base64Url.encode(publicKey.bytes),
    };
    expect(await LicenseIssuer.validateKey(payload), true);
    const installation = '0123456789ABCDEF0123456789ABCDEF';
    final signature = await algorithm.sign(
      utf8.encode('GSL1|' + installation), keyPair: pair);
    expect(signature.bytes.length, 64);
    final another = await algorithm.verify(
      utf8.encode('GSL1|' + installation), signature: signature);
    expect(another, true);
    pair.destroy();
  });
  test('No admite IDs inválidos', () {
    expect(LicenseIssuer.isValidInstallationCode('0123456789ABCDEF0123456789ABCDEF'), true);
    expect(LicenseIssuer.isValidInstallationCode('ABCD'), false);
    expect(LicenseIssuer.isValidInstallationCode('A4Y3-B7K2'), true);
    expect(LicenseIssuer.normalizeInstallationCode('a4y3-b7k2'), 'A4Y3B7K2');
  });
}

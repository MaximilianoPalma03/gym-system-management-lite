import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import '../data/gym_repository.dart';

/// Archivo versionado: cabecera JSON (sin secretos) + datos AES-256-GCM.
/// PBKDF2-HMAC-SHA256 protege la contraseña; 210 000 iteraciones.
class BackupService {
  const BackupService(this.repository);
  final GymRepository repository;

  static final _aes = AesGcm.with256bits();
  static final _kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 210000, bits: 256);

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
  }

  Future<Uint8List> exportEncrypted(String password) async {
    if (password.length < 8) throw ArgumentError('La contraseña debe tener al menos 8 caracteres.');
    final data = jsonEncode(await repository.exportData());
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)), nonce: salt,
    );
    final box = await _aes.encrypt(utf8.encode(data), secretKey: key, nonce: nonce);
    final envelope = {
      'format': 'gym-lite-encrypted',
      'version': 1,
      'kdf': 'pbkdf2-sha256-210000',
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<Map<String, dynamic>> decrypt(Uint8List bytes, String password) async {
    if (bytes.length > 20000000) throw const FormatException('Archivo demasiado grande.');
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'gym-lite-encrypted' ||
        decoded['version'] != 1 || decoded['kdf'] != 'pbkdf2-sha256-210000') {
      throw const FormatException('No es un respaldo compatible.');
    }
    final salt = base64Decode(decoded['salt'] as String);
    final nonce = base64Decode(decoded['nonce'] as String);
    if (salt.length != 16 || nonce.length != 12) throw const FormatException('Respaldo dañado.');
    final key = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)), nonce: salt,
    );
    final box = SecretBox(
      base64Decode(decoded['ciphertext'] as String),
      nonce: nonce, mac: Mac(base64Decode(decoded['mac'] as String)),
    );
    final plain = await _aes.decrypt(box, secretKey: key);
    final content = jsonDecode(utf8.decode(plain));
    if (content is! Map<String, dynamic>) throw const FormatException('Datos no válidos.');
    return content;
  }
}

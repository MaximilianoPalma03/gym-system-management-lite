/// Convierte teléfonos nacionales en formato internacional apto para WhatsApp.
/// Para Argentina se espera código de área + número SIN 0 inicial ni 15.
String normalizePhone(String raw, String country) {
  final text = raw.trim();
  if (text.isEmpty) return '';
  if (text.startsWith('+')) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[1-9]\d{9,14}$').hasMatch(digits)) {
      throw const FormatException('Número internacional inválido.');
    }
    return '+' + digits;
  }
  final digits = text.replaceAll(RegExp(r'[\s()-]'), '');
  if (!RegExp(r'^\d+$').hasMatch(digits)) {
    throw const FormatException('Ingresá solo números.');
  }
  if (country == 'AR') {
    if (digits.length != 10 || digits.startsWith('0')) {
      throw const FormatException('Argentina: 10 dígitos, sin 0 ni 15.');
    }
    return '+549' + digits;
  }
  if (country == 'CL') {
    if (digits.length != 9 || !digits.startsWith('9')) {
      throw const FormatException('Chile: celular de 9 dígitos (comienza con 9).');
    }
    return '+56' + digits;
  }
  if (country == 'BR') {
    if (digits.length != 11) {
      throw const FormatException('Brasil: celular de 11 dígitos.');
    }
    return '+55' + digits;
  }
  throw const FormatException('Ingresá el número completo con +código país.');
}

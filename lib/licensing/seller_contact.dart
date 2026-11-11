/// Contacto comercial integrado para solicitar licencias.
class SellerContact {
  const SellerContact._();

  // Es un número de WhatsApp público para contacto con el vendedor;
  // no contiene ninguna clave de licencia, contraseña ni secreto.
  static const String whatsappPhone = '5493544432383';

  static Uri activationRequest(String installationId) {
    final display = installationId.length == 8
        ? installationId.substring(0, 4) + '-' + installationId.substring(4)
        : installationId;
    return Uri.https('wa.me', '/$whatsappPhone', {
      'text': 'Hola, quiero activar Higea Fitness. '
          'Mi código de instalación es: $display',
    });
  }
}

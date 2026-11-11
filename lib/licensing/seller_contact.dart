/// Contacto comercial integrado para solicitar pruebas y licencias.
class SellerContact {
  const SellerContact._();

  // Es un número de WhatsApp público para contacto con el vendedor;
  // no contiene ninguna clave de licencia, contraseña ni secreto.
  static const String whatsappPhone = '5493544432383';

  static Uri activationRequest(
    String installationId, {bool trialExpired = false}) {
    final display = installationId.length == 8
        ? installationId.substring(0, 4) + '-' + installationId.substring(4)
        : installationId;
    final message = trialExpired
        ? 'Hola, quiero activar la licencia comercial de Higea Fitness. '
          'Mi código de instalación es: $display'
        : 'Hola, quiero solicitar una prueba gratuita de 7 días de Higea Fitness. '
          'Mi código de instalación es: $display';
    return Uri.https('wa.me', '/$whatsappPhone', {'text': message});
  }
}

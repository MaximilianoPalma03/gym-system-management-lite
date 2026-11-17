import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:gym_system_management_lite/licensing/license_service.dart';
import 'package:gym_system_management_lite/licensing/license_settings_screen.dart';

void main() {
  testWidgets('La prueba se consulta en Ajustes y se convierte en comercial',
      (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    const id = 'A4Y3B7K2';
    final prefs = SharedPreferencesAsync();
    await prefs.setString('gym_lite_installation_v1', id);
    final algorithm = Ed25519();
    final keys = await algorithm.newKeyPair();
    final public = await keys.extractPublicKey();
    final service = LicenseService(
      preferences: prefs,
      publicKeyBase64: base64Url.encode(public.bytes),
      clock: () => DateTime.utc(2026, 11, 17),
    );

    Future<String> signed(String type) async {
      final signature = await algorithm.sign(
        utf8.encode('GSL2|$type|$id'), keyPair: keys);
      return 'GSL2-${type == 'trial' ? 'T' : 'P'}-'
          '${base64Url.encode(signature.bytes).replaceAll('=', '')}';
    }

    expect(await service.activate(await signed('trial')), isTrue);
    await tester.pumpWidget(MaterialApp(
      home: LicenseSettingsScreen(service: service)));
    await tester.pumpAndSettle();

    expect(find.text('Prueba gratuita activa'), findsOneWidget);
    expect(find.textContaining('Quedan 7 días de prueba'), findsOneWidget);
    expect(find.text('Activar compra'), findsOneWidget);

    await tester.enterText(find.byType(TextField), await signed('permanent'));
    await tester.ensureVisible(find.text('Activar compra'));
    await tester.tap(find.text('Activar compra'));
    await tester.pumpAndSettle();

    expect(find.text('Licencia comercial activa'), findsOneWidget);
    expect(find.text('Activar compra'), findsNothing);
    expect((await service.status()).isPermanent, isTrue);
    keys.destroy();
  });
}

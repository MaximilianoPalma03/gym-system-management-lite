import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system_management_lite/licensing/license_gate.dart';

void main() {
  testWidgets('La app de desarrollo abre su interfaz sin pedir licencia', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LicenseGate(
        child: Scaffold(body: Center(child: Text('Gym Lite'))),
      ),
    ));
    expect(find.text('Gym Lite'), findsOneWidget);
  });
}

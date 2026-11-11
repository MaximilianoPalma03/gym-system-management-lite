import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:gym_lite_license_manager/main.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('El administrador ofrece prueba gratuita y licencia comercial',
      (tester) async {
    await tester.pumpWidget(const LicenseManagerApp());
    await tester.pumpAndSettle();
    expect(find.text('Emisor privado offline'), findsOneWidget);
    await tester.tap(find.text('Crear clave maestra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(find.text('Tipo de licencia'), findsOneWidget);
    expect(find.text('Prueba · 7 días'), findsOneWidget);
    expect(find.text('Comercial'), findsOneWidget);
    expect(find.text('Generar prueba gratuita'), findsOneWidget);

    await tester.tap(find.text('Comercial'));
    await tester.pumpAndSettle();
    expect(find.text('Generar licencia permanente'), findsOneWidget);
  });
}

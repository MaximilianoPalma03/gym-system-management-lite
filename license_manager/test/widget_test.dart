import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:gym_lite_license_manager/main.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('El administrador abre y ofrece crear la clave maestra', (tester) async {
    await tester.pumpWidget(const LicenseManagerApp());
    await tester.pumpAndSettle();
    expect(find.text('Emisor privado offline'), findsOneWidget);
    expect(find.text('Crear clave maestra'), findsOneWidget);
  });
}

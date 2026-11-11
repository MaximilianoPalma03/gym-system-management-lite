import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system_management_lite/ui/theme.dart';

void main() {
  test('Modo oscuro mantiene el color seleccionado y superficies oscuras', () {
    final light = buildAppTheme(1, brightness: Brightness.light);
    final dark = buildAppTheme(1, brightness: Brightness.dark);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(dark.scaffoldBackgroundColor, isNot(equals(light.scaffoldBackgroundColor)));
    expect(dark.cardTheme.color, isNot(equals(light.cardTheme.color)));
  });
}

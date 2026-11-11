import 'dart:io';

/// Configura el splash nativo de Android generado por "flutter create".
/// Es repetible: no borra los datos ni vuelve a crear el proyecto.
/// Ejecutar desde la raíz: dart run tool/configurar_splash.dart
Future<void> main() async {
  final res = Directory('android/app/src/main/res');
  if (!await res.exists()) {
    stderr.writeln('Primero ejecutá flutter create --platforms=android .');
    exitCode = 1;
    return;
  }

  Future<void> write(String suffix, String contents) async {
    final file = File(res.path + '/' + suffix);
    await file.parent.create(recursive: true);
    await file.writeAsString(contents, flush: true);
  }

  await write('values/gym_lite_splash_colors.xml', '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="gym_lite_splash_background">#11243B</color>
</resources>
''');

  await write('drawable/gym_lite_splash_icon.xml', '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="160dp" android:height="160dp"
    android:viewportWidth="160" android:viewportHeight="160">
    <path android:fillColor="#36A676"
        android:pathData="M80,12 C117.6,12 148,42.4 148,80 C148,117.6 117.6,148 80,148 C42.4,148 12,117.6 12,80 C12,42.4 42.4,12 80,12 Z"/>
    <path android:fillColor="#FFFFFF"
        android:pathData="M49,75 L111,75 L111,85 L49,85 Z"/>
    <path android:fillColor="#FFFFFF"
        android:pathData="M37,61 L47,61 L47,99 L37,99 Z M113,61 L123,61 L123,99 L113,99 Z"/>
    <path android:fillColor="#FFFFFF"
        android:pathData="M50,68 L57,68 L57,92 L50,92 Z M103,68 L110,68 L110,92 L103,92 Z"/>
</vector>
''');

  await write('drawable/gym_lite_launch_background.xml',
      '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/gym_lite_splash_background" />
    <item android:gravity="center" android:drawable="@mipmap/ic_launcher" />
</layer-list>
''');

  final launchStyle = RegExp(
      r'(<style\s+name="LaunchTheme"[^>]*>)([\s\S]*?)(</style>)');

  Future<void> editTheme(String folder,
      {required bool android12, required bool dark}) async {
    final path = res.path + '/' + folder + '/styles.xml';
    final file = File(path);
    var xml = await file.exists() ? await file.readAsString() : '';
    if (xml.isEmpty && !android12) {
      throw StateError('No se encontró ' + path + '. Ejecutá flutter create.');
    }
    if (xml.isEmpty) {
      xml = '<?xml version="1.0" encoding="utf-8"?>\n'
          '<resources>\n'
          '    <style name="LaunchTheme" parent="@android:style/Theme.' +
          (dark ? 'Black' : 'Light') +
          '.NoTitleBar">\n'
          '    </style>\n'
          '</resources>\n';
    }
    if (!launchStyle.hasMatch(xml)) {
      throw StateError('No se encontró LaunchTheme en ' + path);
    }
    xml = xml.replaceFirstMapped(launchStyle, (m) {
      var body = m.group(2)!;
      body = body.replaceAll(
          RegExp(r'<item\s+name="android:windowBackground">[^<]*</item>'), '');
      body += '\n        <item name="android:windowBackground">'
          '@drawable/gym_lite_launch_background</item>\n';
      if (android12) {
        for (final attribute in [
          'android:windowSplashScreenBackground',
          'android:windowSplashScreenAnimatedIcon',
          'android:windowSplashScreenIconBackgroundColor',
        ]) {
          body = body.replaceAll(
              RegExp('<item\\s+name="' + attribute + '">[^<]*</item>'), '');
        }
        body += '        <item name="android:windowSplashScreenBackground">'
            '@color/gym_lite_splash_background</item>\n'
            '        <item name="android:windowSplashScreenAnimatedIcon">'
            '@mipmap/ic_launcher</item>\n'
            '        <item name="android:windowSplashScreenIconBackgroundColor">'
            '@color/gym_lite_splash_background</item>\n';
      }
      return m.group(1)! + body + m.group(3)!;
    });
    await file.parent.create(recursive: true);
    await file.writeAsString(xml, flush: true);
  }

  await editTheme('values', android12: false, dark: false);
  await editTheme('values-night', android12: false, dark: true);
  await editTheme('values-v31', android12: true, dark: false);
  await editTheme('values-night-v31', android12: true, dark: true);
  // Cambiar solo el rótulo visible, nunca el applicationId.
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!await manifest.exists()) {
    throw StateError('Falta AndroidManifest.xml; ejecutá flutter create.');
  }
  final original = await manifest.readAsString();
  final label = RegExp(r'android:label="[^"]*"');
  if (!label.hasMatch(original)) {
    throw StateError('No se encontró android:label en el manifiesto.');
  }
  await manifest.writeAsString(
    original.replaceFirst(label, 'android:label="Higea Fitness"'),
    flush: true,
  );
  stdout.writeln('Splash y nombre Higea Fitness configurados.');

}

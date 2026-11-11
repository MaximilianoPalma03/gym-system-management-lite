import 'dart:io';

/// Configura Gradle Kotlin para firmar el APK comercial.
/// Nunca almacena la clave privada ni imprime contraseñas.
/// Ejecutar desde la raíz: dart run tool/configurar_firma_android.dart
Future<void> main() async {
  const commercialId = 'ar.com.higeafitness.app';
  const oldGeneratedId = 'com.example.gym_system_management_lite';
  final buildFile = File('android/app/build.gradle.kts');
  if (!await buildFile.exists()) {
    throw StateError('Falta android/app/build.gradle.kts. Generá Android primero.');
  }

  final propertiesFile = File('android/key.properties');
  if (!await propertiesFile.exists()) {
    throw StateError('Falta android/key.properties. Consultá '
        'docs/DISTRIBUCION_COMERCIAL.md para crear la firma.');
  }

  final props = await propertiesFile.readAsLines();
  String readProperty(String name) {
    for (final raw in props) {
      final line = raw.trim();
      if (line.startsWith('#')) continue;
      if (line.startsWith('$name=')) {
        return line.substring(name.length + 1).trim();
      }
    }
    throw StateError('Falta $name en android/key.properties.');
  }

  for (final name in ['storePassword', 'keyPassword', 'keyAlias', 'storeFile']) {
    final value = readProperty(name);
    if (value.isEmpty || value.contains('REEMPLAZAR') || value.contains('<')) {
      throw StateError('No se configuró $name.');
    }
  }
  final storeFile = readProperty('storeFile');
  if (storeFile.contains('\\')) {
    throw StateError('Usá barras / en storeFile: C:/Users/usuario/HigeaKeys/higea-release.jks');
  }
  if (!await File(storeFile).exists()) {
    throw StateError('No encontré el archivo de firma: $storeFile. '
        'Si ya tenías una firma, no generes otra.');
  }

  var gradle = await buildFile.readAsString();
  final appId = RegExp(r'applicationId\s*=\s*"([^"]+)"');
  final originalId = appId.firstMatch(gradle)?.group(1);
  if (originalId == null) {
    throw StateError('No se encontró applicationId en build.gradle.kts.');
  }
  if (originalId != oldGeneratedId && originalId != commercialId) {
    throw StateError('applicationId actual ($originalId) no es el esperado. '
        'No se cambiará automáticamente.');
  }
  gradle = gradle.replaceFirst(appId, 'applicationId = "$commercialId"');

  if (!gradle.contains('import java.util.Properties')) {
    gradle = 'import java.util.Properties\n'
        'import java.io.FileInputStream\n\n$gradle';
  }

  if (!gradle.contains('val higeaSigningProperties = Properties()')) {
    final marker = RegExp(r'^android\s*\{', multiLine: true);
    if (!marker.hasMatch(gradle)) {
      throw StateError('No se encontró el bloque android en Gradle.');
    }
    gradle = gradle.replaceFirst(marker, '''
val higeaSigningProperties = Properties()
val higeaSigningPropertiesFile = rootProject.file("key.properties")
if (higeaSigningPropertiesFile.exists()) {
    higeaSigningProperties.load(FileInputStream(higeaSigningPropertiesFile))
}

android {''');
  }

  if (!gradle.contains('create("release")')) {
    final marker = RegExp(r'^\s*buildTypes\s*\{', multiLine: true);
    if (!marker.hasMatch(gradle)) {
      throw StateError('No se encontró buildTypes en Gradle.');
    }
    gradle = gradle.replaceFirst(marker, '''
    signingConfigs {
        create("release") {
            keyAlias = higeaSigningProperties.getProperty("keyAlias")
            keyPassword = higeaSigningProperties.getProperty("keyPassword")
            storeFile = higeaSigningProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = higeaSigningProperties.getProperty("storePassword")
        }
    }
    buildTypes {''');
  }

  // Debug y comercial permanecen separados: no mezclar sus datos ni firmas.
  if (!gradle.contains('applicationIdSuffix = ".dev"')) {
    final marker = RegExp(r'buildTypes\s*\{');
    if (!marker.hasMatch(gradle)) {
      throw StateError('No se encontró buildTypes para separar debug.');
    }
    gradle = gradle.replaceFirst(marker, '''buildTypes {
        debug {
            applicationIdSuffix = ".dev"
        }''');
  }

  final debugSigning = 'signingConfig = signingConfigs.getByName("debug")';
  final releaseSigning = 'signingConfig = signingConfigs.getByName("release")';
  if (gradle.contains(debugSigning)) {
    gradle = gradle.replaceFirst(debugSigning, releaseSigning);
  } else if (!gradle.contains(releaseSigning)) {
    throw StateError('No se encontró la asignación de firma de release esperada.');
  }

  await buildFile.writeAsString(gradle, flush: true);
  stdout.writeln('Gradle preparado para firmar Higea Fitness en release.');
  stdout.writeln('ID comercial: $commercialId');
  stdout.writeln('ID desarrollo: $commercialId.dev');
  stdout.writeln('Firma privada: se utilizará el archivo local existente.');
}

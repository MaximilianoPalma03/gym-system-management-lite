# Ejecutar desde la carpeta raíz del repositorio.
$ErrorActionPreference = 'Stop'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter SDK no está disponible en PATH. Instalalo y ejecutá flutter doctor.'
}
flutter doctor
if ($LASTEXITCODE -ne 0) { Write-Warning 'Revisá los avisos de flutter doctor.' }
flutter create --platforms=android --project-name gym_system_management_lite .
if ($LASTEXITCODE -ne 0) { throw 'No se pudo generar el proyecto Android.' }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Falló flutter pub get.' }
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) { throw 'El análisis detectó errores.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas.' }
Write-Host 'Preparación completa. Conectá un Android y ejecutá: flutter run' -ForegroundColor Green
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^\d+\.\d+\.\d+$')]
  [string]$VersionName,

  [Parameter(Mandatory = $true)]
  [ValidateRange(1, 2147483647)]
  [int]$VersionCode
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Run-Checked {
  param([string]$Command, [string[]]$Arguments)
  & $Command @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Falló $Command (código de salida $LASTEXITCODE). No se generó una distribución verificada."
  }
}

Push-Location $root
try {
  $publicFile = Join-Path $root 'android/higea-public-key.txt'
  $keyConfig = Join-Path $root 'android/key.properties'
  if (-not (Test-Path $publicFile)) {
    throw 'Falta android/higea-public-key.txt con la clave pública copiada desde License Manager.'
  }
  if (-not (Test-Path $keyConfig)) {
    throw 'Falta android/key.properties con la firma privada de Android. Consultá la guía.'
  }
  $publicKey = (Get-Content -Path $publicFile -Raw).Trim()
  if ($publicKey -notmatch '^[A-Za-z0-9_-]{43}=?$') {
    throw 'La clave pública no tiene el formato esperado para Ed25519. No pegues una licencia ni el archivo .gslkey.'
  }

  foreach ($asset in @(
    'assets/branding/higea_icon.png',
    'assets/branding/higea_icon_foreground.png',
    'assets/branding/higea_splash.png'
  )) {
    if (-not (Test-Path $asset)) {
      throw "Falta el recurso gráfico: $asset"
    }
  }

  $filename = "Higea-Fitness-v$VersionName-$VersionCode.apk"
  $distDir = Join-Path $root 'dist'
  $target = Join-Path $distDir $filename
  if (Test-Path $target) {
    throw "Ya existe esta versión en dist: $filename. No sobrescribas APKs distribuidos."
  }

  Write-Host "Preparando Higea Fitness $VersionName ($VersionCode)..." -ForegroundColor Cyan
  Run-Checked 'flutter' @('pub', 'get')
  Run-Checked 'dart' @('run', 'tool/configurar_firma_android.dart')
  Run-Checked 'dart' @('run', 'flutter_launcher_icons')
  Run-Checked 'dart' @('run', 'tool/configurar_splash.dart')
  # El propio flutter analyze muestra las advertencias con su archivo y línea.
  # --no-fatal-infos permite sugerencias de estilo, no advertencias ni errores.
  Run-Checked 'flutter' @('analyze', '--no-fatal-infos')
  Run-Checked 'flutter' @('test')
  Run-Checked 'flutter' @('build', 'apk', '--release',
    "--build-name=$VersionName", "--build-number=$VersionCode",
    "--dart-define=GYM_LITE_PUBLIC_KEY=$publicKey")

  $apk = Join-Path $root 'build/app/outputs/flutter-apk/app-release.apk'
  if (-not (Test-Path $apk)) {
    throw 'No se encontró el APK release de Flutter.'
  }

  $sdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) {
    $env:ANDROID_HOME
  } else { Join-Path $env:LOCALAPPDATA 'Android/Sdk' }

  $toolsDir = Join-Path $sdk 'build-tools'
  if (-not (Test-Path $toolsDir)) {
    throw "No se encontraron las herramientas de Android en: $toolsDir"
  }

  $signer = Get-ChildItem $toolsDir -Directory |
    Sort-Object { try { [version]$_.Name } catch { [version]'0.0' } } -Descending |
    ForEach-Object { Join-Path $_.FullName 'apksigner.bat' } |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1

  if (-not $signer) {
    throw 'No se encontró apksigner.bat. Instalá Android SDK Build-Tools antes de distribuir.'
  }

  # Java puede escribir avisos en stderr aunque apksigner termine bien.
  # PowerShell 5.1 interpreta stderr de procesos nativos como NativeCommandError
  # cuando ErrorActionPreference=Stop. Capturamos cada flujo por separado
  # y decidimos el resultado con ExitCode, sin ignorar fallos reales.
  $verifyOut = Join-Path $env:TEMP ("higea-apksigner-" + [guid]::NewGuid().ToString('N') + ".out")
  $verifyErr = Join-Path $env:TEMP ("higea-apksigner-" + [guid]::NewGuid().ToString('N') + ".err")
  try {
    $cmdArgs = '/d /s /c ""' + $signer + '" verify --print-certs "' + $apk + '""'
    $verification = Start-Process -FilePath $env:ComSpec -ArgumentList $cmdArgs `
      -Wait -PassThru -NoNewWindow `
      -RedirectStandardOutput $verifyOut -RedirectStandardError $verifyErr
    $signatureReport = @(Get-Content -Path $verifyOut)
    $verificationErrors = @(Get-Content -Path $verifyErr)
    if ($verification.ExitCode -ne 0) {
      $detail = ($verificationErrors | Select-Object -Last 8) -join ' | '
      throw "La firma del APK NO pasó la verificación (salida $($verification.ExitCode)). $detail"
    }
    if (-not ($signatureReport -match 'Signer #1 certificate SHA-256 digest:')) {
      throw 'No se pudo obtener el certificado firmante. No distribuir.'
    }
    if ($verificationErrors.Count -gt 0) {
      Write-Host 'apksigner mostró advertencias de Java; la firma pasó la verificación.' -ForegroundColor Yellow
    }
  } finally {
    Remove-Item -LiteralPath $verifyOut, $verifyErr -Force -ErrorAction SilentlyContinue
  }

  New-Item -ItemType Directory -Force -Path $distDir | Out-Null
  Copy-Item -Path $apk -Destination $target
  $hash = (Get-FileHash -Path $target -Algorithm SHA256).Hash
  Set-Content -Path (Join-Path $distDir "$filename.sha256.txt") -Value "$hash  $filename"
  Set-Content -Path (Join-Path $distDir "$filename.firma.txt") -Value $signatureReport

  Write-Host 'APK comercial verificado:' -ForegroundColor Green
  Write-Host $target
  Write-Host "SHA256: $hash"
  Write-Host 'Certificado de firma:'
  $signatureReport | Where-Object { $_ -match 'SHA-256 digest:' } | ForEach-Object { Write-Host $_ }
  Write-Host 'Guardá el archivo JKS y su contraseña fuera del repositorio.' -ForegroundColor Yellow
} finally {
  Pop-Location
}

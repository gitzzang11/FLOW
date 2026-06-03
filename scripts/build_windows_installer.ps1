param(
  [string] $InnoSetupCompiler
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$issPath = Join-Path $repoRoot 'windows\installer\flow.iss'

function Find-InnoSetupCompiler {
  param([string] $ExplicitPath)

  if ($ExplicitPath) {
    if (Test-Path $ExplicitPath) {
      return (Resolve-Path $ExplicitPath).Path
    }
    throw "Inno Setup compiler was not found at '$ExplicitPath'."
  }

  $command = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $candidates = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
    (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe')
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return (Resolve-Path $candidate).Path
    }
  }

  throw 'Install Inno Setup 6 or pass -InnoSetupCompiler C:\Path\To\ISCC.exe.'
}

Push-Location $repoRoot
try {
  $versionLine = Get-Content 'pubspec.yaml' |
    Where-Object { $_ -match '^version:\s*(.+)$' } |
    Select-Object -First 1

  if (-not $versionLine -or $versionLine -notmatch '^version:\s*([^\+]+)') {
    throw 'Could not read the app version from pubspec.yaml.'
  }

  $appVersion = $Matches[1].Trim()
  $iscc = Find-InnoSetupCompiler $InnoSetupCompiler

  flutter pub get
  flutter build windows --release

  & $iscc "/DMyAppVersion=$appVersion" $issPath

  Write-Host "Installer created in build\installer."
}
finally {
  Pop-Location
}

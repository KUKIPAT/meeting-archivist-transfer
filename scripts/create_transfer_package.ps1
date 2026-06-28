param(
  [string]$SourceDist = "E:\Finetune\QWEN3_ASR\dist",
  [string]$OutputDir = ".\release_payload",
  [string]$PackageName = "runtime-package",
  [string]$VolumeSize = "1200m",
  [string]$SevenZipPath = ""
)

$ErrorActionPreference = "Stop"

function Resolve-SevenZip {
  param([string]$PreferredPath)

  if ($PreferredPath -and (Test-Path -LiteralPath $PreferredPath)) {
    return (Resolve-Path -LiteralPath $PreferredPath).Path
  }

  $fromPath = Get-Command 7z.exe -ErrorAction SilentlyContinue
  if ($fromPath) {
    return $fromPath.Source
  }

  $candidates = @(
    "$env:ProgramFiles\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
    "$env:LOCALAPPDATA\Programs\7-Zip\7z.exe"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
      return $candidate
    }
  }

  throw "7z.exe was not found. Install 7-Zip or pass -SevenZipPath."
}

function Require-File {
  param(
    [string]$Path,
    [string]$Label
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "$Label not found: $Path"
  }
}

$SourceDist = (Resolve-Path -LiteralPath $SourceDist).Path
$OutputDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDir)
$SevenZipPath = Resolve-SevenZip -PreferredPath $SevenZipPath

$msiPath = Join-Path $SourceDist "AI-Meeting-Archivist-Offline.msi"
Require-File -Path $msiPath -Label "MSI"

$cabFiles = Get-ChildItem -LiteralPath $SourceDist -Filter "cab*.cab" -File | Sort-Object Name
if ($cabFiles.Count -eq 0) {
  throw "No cab*.cab files found in $SourceDist"
}

if (Test-Path -LiteralPath $OutputDir) {
  Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$installText = @"
AI 회의기록관 설치 파일 전달본

1. 이 폴더의 파일을 모두 같은 위치에 둡니다.
2. 7-Zip으로 runtime-package.7z.001 파일을 선택해 압축을 풉니다.
3. 압축 해제 후 나온 AI-Meeting-Archivist-Offline.msi와 cab*.cab 파일을 같은 폴더에 둡니다.
4. AI-Meeting-Archivist-Offline.msi를 실행해 설치합니다.

해시 확인 예시:

Get-ChildItem .\runtime-package.7z.* | Get-FileHash -Algorithm SHA256

주의:
- cab*.cab 파일이 MSI와 같은 폴더에 있어야 설치됩니다.
- 회사 자료나 회의 녹음은 이 전달본에 포함되어 있지 않습니다.
- 다운로드 후 GitHub Release는 삭제 예정입니다.
"@

$installPath = Join-Path $OutputDir "INSTALL_KO.txt"
Set-Content -LiteralPath $installPath -Value $installText -Encoding UTF8

$archivePath = Join-Path $OutputDir "$PackageName.7z"
$inputs = @($msiPath) + @($cabFiles.FullName)

Write-Host "Using 7-Zip: $SevenZipPath"
Write-Host "Creating split archive in $OutputDir"
& $SevenZipPath a -t7z $archivePath $inputs "-v$VolumeSize" -mx=5
if ($LASTEXITCODE -ne 0) {
  throw "7-Zip failed with exit code $LASTEXITCODE"
}

$hashPath = Join-Path $OutputDir "SHA256SUMS.txt"
Get-ChildItem -LiteralPath $OutputDir -File |
  Sort-Object Name |
  ForEach-Object {
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLowerInvariant()
    "$hash  $($_.Name)"
  } | Set-Content -LiteralPath $hashPath -Encoding ASCII

Write-Host "Transfer package created:"
Get-ChildItem -LiteralPath $OutputDir -File | Sort-Object Name | Format-Table Name, Length -AutoSize


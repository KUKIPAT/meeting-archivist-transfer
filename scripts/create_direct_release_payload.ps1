param(
  [string]$SourceDist = "E:\Finetune\QWEN3_ASR\dist",
  [string]$OutputDir = ".\release_payload_direct"
)

$ErrorActionPreference = "Stop"

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

$msiPath = Join-Path $SourceDist "AI-Meeting-Archivist-Offline.msi"
Require-File -Path $msiPath -Label "MSI"

$cabFiles = Get-ChildItem -LiteralPath $SourceDist -Filter "cab*.cab" -File | Sort-Object Name
if ($cabFiles.Count -eq 0) {
  throw "No cab*.cab files found in $SourceDist"
}

$tooLarge = @($cabFiles | Where-Object { $_.Length -ge 2GB })
if ($tooLarge.Count -gt 0) {
  $names = ($tooLarge | ForEach-Object { $_.Name }) -join ", "
  throw "These files are too large for GitHub Release assets: $names"
}

if (Test-Path -LiteralPath $OutputDir) {
  Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Copy-Item -LiteralPath $msiPath -Destination $OutputDir -Force
foreach ($cab in $cabFiles) {
  Copy-Item -LiteralPath $cab.FullName -Destination $OutputDir -Force
}

$installText = @"
AI 회의기록관 설치 파일 전달본

다운로드:
1. GitHub Release asset의 AI-Meeting-Archivist-Offline.msi 파일을 받습니다.
2. cab1.cab부터 cab*.cab 파일을 모두 받습니다.
3. 모든 파일을 같은 폴더에 둡니다.

설치:
1. AI-Meeting-Archivist-Offline.msi를 실행합니다.
2. 설치 중 cab 파일을 찾지 못하면 MSI와 cab*.cab가 같은 폴더에 있는지 확인합니다.

해시 확인 예시:

Get-ChildItem .\AI-Meeting-Archivist-Offline.msi, .\cab*.cab | Get-FileHash -Algorithm SHA256

주의:
- cab*.cab 파일이 하나라도 빠지면 설치가 실패합니다.
- 회사 자료나 회의 녹음은 이 전달본에 포함되어 있지 않습니다.
- 다운로드 후 GitHub Release는 삭제 예정입니다.
"@

Set-Content -LiteralPath (Join-Path $OutputDir "INSTALL_KO.txt") -Value $installText -Encoding UTF8

$hashPath = Join-Path $OutputDir "SHA256SUMS.txt"
Get-ChildItem -LiteralPath $OutputDir -File |
  Sort-Object Name |
  Where-Object { $_.Name -ne "SHA256SUMS.txt" } |
  ForEach-Object {
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLowerInvariant()
    "$hash  $($_.Name)"
  } | Set-Content -LiteralPath $hashPath -Encoding ASCII

Write-Host "Direct release payload created:"
Get-ChildItem -LiteralPath $OutputDir -File | Sort-Object Name | Format-Table Name, Length -AutoSize


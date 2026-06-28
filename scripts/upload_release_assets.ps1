param(
  [Parameter(Mandatory = $true)]
  [string]$Tag,

  [string]$Title = "",

  [string]$PayloadDir = ".\release_payload",

  [string]$Repo = "KUKIPAT/meeting-archivist-transfer"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh.exe -ErrorAction SilentlyContinue)) {
  throw "GitHub CLI gh.exe was not found."
}

$PayloadDir = (Resolve-Path -LiteralPath $PayloadDir).Path
$assets = Get-ChildItem -LiteralPath $PayloadDir -File | Sort-Object Name
if ($assets.Count -eq 0) {
  throw "No files found in $PayloadDir"
}

if (-not $Title) {
  $Title = $Tag
}

$notes = @"
Temporary transfer release.

Download all assets into the same folder and verify SHA256SUMS.txt.

This release is intended to be deleted after download is complete.
"@

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
gh release view $Tag --repo $Repo *> $null
$releaseViewExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference

if ($releaseViewExitCode -ne 0) {
  Write-Host "Creating release $Tag"
  gh release create $Tag --repo $Repo --title $Title --notes $notes
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to create release $Tag"
  }
} else {
  Write-Host "Release $Tag already exists. Uploading assets with --clobber."
}

foreach ($asset in $assets) {
  Write-Host "Uploading $($asset.Name)"
  gh release upload $Tag $asset.FullName --repo $Repo --clobber
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to upload $($asset.Name)"
  }
}

Write-Host "Release assets uploaded:"
gh release view $Tag --repo $Repo --web

param([string]$Destination = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (-not $Destination) { $Destination = Join-Path (Split-Path $projectRoot -Parent) '交付' }
$Destination = [IO.Path]::GetFullPath($Destination)
New-Item -ItemType Directory -Path $Destination -Force | Out-Null
Push-Location $projectRoot
try {
  if (git status --porcelain) { throw 'Commit the source before packaging.' }
  node scripts/build.mjs
  if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
  $revision = (git rev-parse HEAD).Trim()
  $sourceZip = Join-Path $Destination 'MoonRow-0.1.0-source.zip'
  $portableZip = Join-Path $Destination 'MoonRow-0.1.0-portable.zip'
  git archive --format=zip "--output=$sourceZip" HEAD
  if ($LASTEXITCODE -ne 0) { throw 'Source archive failed.' }
  Copy-Item -LiteralPath $sourceZip -Destination $portableZip -Force
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [IO.Compression.ZipFile]::Open($portableZip, [IO.Compression.ZipArchiveMode]::Update)
  try {
    $artifactPath = Join-Path $projectRoot 'dist/moonrow.cjs'
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $artifactPath, 'dist/moonrow.cjs') | Out-Null
    $manifest = [ordered]@{
      name = 'MoonRow'; version = '0.1.0'; source_commit = $revision
      runtime_requirement = 'Node.js >= 22 (tested 24.14.0)'
      artifact_sha256 = (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash.ToLower()
      built_at_utc = [DateTime]::UtcNow.ToString('o')
    } | ConvertTo-Json
    $entry = $zip.CreateEntry('delivery.json')
    $writer = [IO.StreamWriter]::new($entry.Open(), [Text.UTF8Encoding]::new($false))
    try { $writer.Write($manifest) } finally { $writer.Dispose() }
  } finally { $zip.Dispose() }
  Get-FileHash -LiteralPath $sourceZip,$portableZip -Algorithm SHA256 |
    Select-Object @{Name='file';Expression={Split-Path $_.Path -Leaf}},Hash |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Destination 'SHA256.json') -Encoding utf8
  Write-Output "Packaged source and ready-to-run archives at $Destination"
} finally { Pop-Location }

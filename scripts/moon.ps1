param([Parameter(ValueFromRemainingArguments=$true)][string[]]$MoonArgs)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$localToolchain = Join-Path (Split-Path $projectRoot -Parent) '.tools/moon'
if (Test-Path -LiteralPath (Join-Path $localToolchain 'bin/moon.exe')) {
  $env:MOON_HOME = $localToolchain
  $moonExecutable = Join-Path $localToolchain 'bin/moon.exe'
} else {
  $moonExecutable = (Get-Command moon -ErrorAction Stop).Source
}
Push-Location $projectRoot
try { & $moonExecutable @MoonArgs; $result = $LASTEXITCODE }
finally { Pop-Location }
exit $result

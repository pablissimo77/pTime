param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = 'Stop'
$RootDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$DistDir = Join-Path $RootDir 'dist'
$StageDir = Join-Path $DistDir "pTime-$Version-windows-x64"

Remove-Item $StageDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item $StageDir -ItemType Directory -Force | Out-Null

Copy-Item (Join-Path $RootDir 'ptime.exe') $StageDir
Copy-Item (Join-Path $RootDir 'sqlite3.dll') $StageDir
Copy-Item (Join-Path $RootDir 'readme.md'), (Join-Path $RootDir 'LICENSE'), (Join-Path $RootDir 'EULA.md') $StageDir

$ZipPath = Join-Path $DistDir "pTime-$Version-windows-x64.zip"
Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $StageDir '*') -DestinationPath $ZipPath
Remove-Item $StageDir -Recurse -Force

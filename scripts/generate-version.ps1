param(
    [string]$ProjectFile = 'ptime.lpi'
)

$ErrorActionPreference = 'Stop'
$RootDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ProjectPath = Join-Path $RootDir $ProjectFile

if (-not (Test-Path $ProjectPath)) {
    throw "Project file not found: $ProjectPath"
}

[xml]$Project = Get-Content -Raw $ProjectPath
$VersionInfo = $Project.CONFIG.ProjectOptions.VersionInfo
$Major = [int]$VersionInfo.MajorVersionNr.Value
$Minor = [int]$VersionInfo.MinorVersionNr.Value
$Revision = [int]$VersionInfo.RevisionNr.Value
$Version = "$Major.$Minor.$Revision"

@("const", "  PTIME_VERSION = '$Version';") |
    Set-Content -Encoding ASCII (Join-Path $RootDir 'version.inc')

Write-Output $Version

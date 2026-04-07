[CmdletBinding()]
param(
    [string]$WorkspacePath = ".",
    [string]$LogsPath = ".",
    [string]$TempPath = $env:TEMP,
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$combineScript = Join-Path $scriptRoot "combine-probes.ps1"

$probeFacts = & $combineScript `
    -WorkspacePath $WorkspacePath `
    -LogsPath $LogsPath `
    -TempPath $TempPath

$json = ($probeFacts | Out-String).Trim()

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $outputDirectory = Split-Path -Parent $OutputPath
    if (-not [string]::IsNullOrWhiteSpace($outputDirectory) -and -not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($OutputPath, $json, [System.Text.Encoding]::UTF8)
}

$json

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$TargetProjectPath,
    [string]$ContextDirName = ".ai-deploy-context",
    [string]$ProbeFactsPath = "E:\project\repo-auto-deployer\runtime\probeFacts.json",
    [switch]$SkipProbeFacts
)

$ErrorActionPreference = "Stop"

function Copy-DirectoryContents {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Source path not found: $SourcePath"
    }

    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    }

    Copy-Item -LiteralPath (Join-Path $SourcePath "*") -Destination $DestinationPath -Recurse -Force
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$targetRoot = Resolve-Path -LiteralPath $TargetProjectPath -ErrorAction Stop
$contextRoot = Join-Path $targetRoot.Path $ContextDirName
$skillsSource = Join-Path $repoRoot "skills-v2"
$probesSource = Join-Path $repoRoot "probes"
$templatePath = Join-Path $PSScriptRoot "..\templates\DEPLOYMENT_AGENT.md"
$startHereTemplatePath = Join-Path $PSScriptRoot "..\templates\START-HERE.md"

if (Test-Path -LiteralPath $contextRoot) {
    Remove-Item -LiteralPath $contextRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $contextRoot -Force | Out-Null

Copy-DirectoryContents -SourcePath $skillsSource -DestinationPath (Join-Path $contextRoot "skills-v2")
Copy-DirectoryContents -SourcePath $probesSource -DestinationPath (Join-Path $contextRoot "probes")

if (-not $SkipProbeFacts -and (Test-Path -LiteralPath $ProbeFactsPath)) {
    Copy-Item -LiteralPath $ProbeFactsPath -Destination (Join-Path $contextRoot "probeFacts.json") -Force
}

if (Test-Path -LiteralPath $templatePath) {
    Copy-Item -LiteralPath $templatePath -Destination (Join-Path $contextRoot "AGENTS.md") -Force
}

if (Test-Path -LiteralPath $startHereTemplatePath) {
    Copy-Item -LiteralPath $startHereTemplatePath -Destination (Join-Path $contextRoot "START-HERE.md") -Force
}

$result = [ordered]@{
    contextRoot = $contextRoot
    copied = [ordered]@{
        skills = Test-Path -LiteralPath (Join-Path $contextRoot "skills-v2")
        probes = Test-Path -LiteralPath (Join-Path $contextRoot "probes")
        probeFacts = Test-Path -LiteralPath (Join-Path $contextRoot "probeFacts.json")
        agentsGuide = Test-Path -LiteralPath (Join-Path $contextRoot "AGENTS.md")
        startHereGuide = Test-Path -LiteralPath (Join-Path $contextRoot "START-HERE.md")
    }
}

$result | ConvertTo-Json -Depth 5

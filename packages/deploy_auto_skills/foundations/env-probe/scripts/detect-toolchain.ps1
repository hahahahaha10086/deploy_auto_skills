[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Get-ToolProbe {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $commandInfo = Get-Command $Command -ErrorAction SilentlyContinue
    if ($null -eq $commandInfo) {
        return @{
            exists = $false
            version = $null
        }
    }

    try {
        $output = & $Command @Arguments 2>&1
        $text = ($output | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE) {
            return @{
                exists = $false
                version = $null
            }
        }

        return @{
            exists = $true
            version = if ([string]::IsNullOrWhiteSpace($text)) { $null } else { $text.Split([Environment]::NewLine)[0].Trim() }
        }
    } catch {
        return @{
            exists = $false
            version = $null
        }
    }
}

$definitions = @(
    @{ key = "docker"; command = "docker"; args = @("--version") },
    @{ key = "dockerCompose"; command = "docker"; args = @("compose", "version") },
    @{ key = "python"; command = "python"; args = @("--version") },
    @{ key = "conda"; command = "conda"; args = @("--version") },
    @{ key = "node"; command = "node"; args = @("--version") },
    @{ key = "pnpm"; command = "pnpm"; args = @("--version") },
    @{ key = "java"; command = "java"; args = @("-version") },
    @{ key = "go"; command = "go"; args = @("version") },
    @{ key = "cmake"; command = "cmake"; args = @("--version") }
)

$tools = [ordered]@{}
$toolVersions = [ordered]@{}

foreach ($definition in $definitions) {
    $probe = Get-ToolProbe -Name $definition.key -Command $definition.command -Arguments $definition.args
    $tools[$definition.key] = [bool]$probe.exists
    if ($probe.version) {
        $toolVersions[$definition.key] = [string]$probe.version
    }
}

$result = [ordered]@{
    tools = $tools
    toolVersions = $toolVersions
}

$result | ConvertTo-Json -Depth 5


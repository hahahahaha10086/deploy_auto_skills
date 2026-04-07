[CmdletBinding()]
param(
    [string]$WorkspacePath = ".",
    [string]$LogsPath = ".",
    [string]$TempPath = $env:TEMP
)

$ErrorActionPreference = "Stop"

function Invoke-ProbeScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [string[]]$Arguments = @()
    )

    try {
        $output = & powershell -ExecutionPolicy Bypass -File $ScriptPath @Arguments
        $text = ($output | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($text)) {
            return @{}
        }

        $parsed = $text | ConvertFrom-Json
        return ConvertTo-Hashtable -Value $parsed
    } catch {
        return @{
            compatibilityHints = @("probe_execution_failed:$([System.IO.Path]::GetFileNameWithoutExtension($ScriptPath))")
        }
    }
}

function ConvertTo-Hashtable {
    param([Parameter(Mandatory = $true)]$Value)

    if ($null -eq $Value) {
        return @{}
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $Value.Keys) {
            $result[$key] = ConvertTo-HashtableValue -Value $Value[$key]
        }
        return $result
    }

    $result = @{}
    foreach ($property in $Value.PSObject.Properties) {
        $result[$property.Name] = ConvertTo-HashtableValue -Value $property.Value
    }
    return $result
}

function ConvertTo-HashtableValue {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [string] -or $Value -is [ValueType]) {
        return $Value
    }

    if ($Value -is [System.Collections.IDictionary]) {
        return ConvertTo-Hashtable -Value $Value
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $items = New-Object System.Collections.Generic.List[object]
        foreach ($item in $Value) {
            $items.Add((ConvertTo-HashtableValue -Value $item))
        }
        return $items
    }

    return ConvertTo-Hashtable -Value $Value
}

function Merge-OrderedMaps {
    param(
        $Base,
        $Incoming
    )

    foreach ($key in $Incoming.Keys) {
        $baseHasKey = $Base.Contains($key)

        if ($baseHasKey -and $Base[$key] -is [System.Collections.IDictionary] -and $Incoming[$key] -is [System.Collections.IDictionary]) {
            Merge-OrderedMaps -Base $Base[$key] -Incoming $Incoming[$key]
            continue
        }

        if ($baseHasKey -and $Base[$key] -is [System.Collections.IEnumerable] -and
            -not ($Base[$key] -is [string]) -and $Incoming[$key] -is [System.Collections.IEnumerable] -and
            -not ($Incoming[$key] -is [string])) {
            $combined = @()
            foreach ($item in $Base[$key]) { $combined += $item }
            foreach ($item in $Incoming[$key]) {
                if ($combined -notcontains $item) {
                    $combined += $item
                }
            }
            $Base[$key] = $combined
            continue
        }

        $Base[$key] = $Incoming[$key]
    }
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$hostFacts = Invoke-ProbeScript -ScriptPath (Join-Path $scriptRoot "detect-host.ps1")
$toolchainFacts = Invoke-ProbeScript -ScriptPath (Join-Path $scriptRoot "detect-toolchain.ps1")
$permissionFacts = Invoke-ProbeScript -ScriptPath (Join-Path $scriptRoot "detect-permissions.ps1") -Arguments @(
    "-WorkspacePath", $WorkspacePath,
    "-LogsPath", $LogsPath,
    "-TempPath", $TempPath
)

$probeFacts = [ordered]@{
    host = [ordered]@{}
    tools = [ordered]@{}
    toolVersions = [ordered]@{}
    capabilities = [ordered]@{}
    permissions = [ordered]@{}
    compatibilityHints = @()
}

Merge-OrderedMaps -Base $probeFacts -Incoming $hostFacts
Merge-OrderedMaps -Base $probeFacts -Incoming $toolchainFacts
Merge-OrderedMaps -Base $probeFacts -Incoming $permissionFacts

$probeFacts.compatibilityHints = @($probeFacts.compatibilityHints)

$probeFacts | ConvertTo-Json -Depth 8

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Test-CommandAvailable {
    param([Parameter(Mandatory = $true)][string]$Name)

    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-OsCaption {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        return [string]$os.Caption
    } catch {
        return "Windows"
    }
}

function Test-GpuAvailable {
    return Test-CommandAvailable -Name "nvidia-smi"
}

$architecture = ""
if ($null -ne $env:PROCESSOR_ARCHITECTURE) {
    $architecture = [string]$env:PROCESSOR_ARCHITECTURE
}

$result = [ordered]@{
    host = [ordered]@{
        osFamily = "windows"
        distribution = Get-OsCaption
        version = [System.Environment]::OSVersion.VersionString
        architecture = $architecture.ToLowerInvariant()
    }
    capabilities = [ordered]@{
        supportsSystemd = $false
        supportsBash = (Test-CommandAvailable -Name "bash")
        supportsPowerShell = $true
        hasGpu = (Test-GpuAvailable)
    }
}

$result | ConvertTo-Json -Depth 5

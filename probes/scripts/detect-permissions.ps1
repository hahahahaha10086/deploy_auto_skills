[CmdletBinding()]
param(
    [string]$WorkspacePath = ".",
    [string]$LogsPath = ".",
    [string]$TempPath = $env:TEMP
)

$ErrorActionPreference = "Stop"

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PathWritable {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    try {
        $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
        $acl = Get-Acl -LiteralPath $resolved.Path -ErrorAction Stop
    } catch {
        return $false
    }

    $writeRights = @(
        [System.Security.AccessControl.FileSystemRights]::Write,
        [System.Security.AccessControl.FileSystemRights]::Modify,
        [System.Security.AccessControl.FileSystemRights]::FullControl,
        [System.Security.AccessControl.FileSystemRights]::CreateFiles,
        [System.Security.AccessControl.FileSystemRights]::WriteData
    )

    foreach ($rule in $acl.Access) {
        if ($rule.AccessControlType -ne [System.Security.AccessControl.AccessControlType]::Allow) {
            continue
        }

        foreach ($right in $writeRights) {
            if (($rule.FileSystemRights -band $right) -ne 0) {
                return $true
            }
        }
    }

    return $false
}

function Test-DockerAccess {
    try {
        $null = & docker ps --format "{{.ID}}" 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Test-ComposeAccess {
    try {
        $null = & docker compose version 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$isElevated = Test-Admin
$canAccessDockerDaemon = Test-DockerAccess
$canRunCompose = Test-ComposeAccess

$compatibilityHints = New-Object System.Collections.Generic.List[string]
if ((Get-Command docker -ErrorAction SilentlyContinue) -and -not $canAccessDockerDaemon) {
    $compatibilityHints.Add("docker_installed_but_daemon_access_denied")
}
if (-not (Test-PathWritable -Path $WorkspacePath)) {
    $compatibilityHints.Add("workspace_not_writable")
}

$result = [ordered]@{
    permissions = [ordered]@{
        executionIdentity = $identity.Name
        isElevated = $isElevated
        canWriteWorkspace = (Test-PathWritable -Path $WorkspacePath)
        canWriteTemp = (Test-PathWritable -Path $TempPath)
        canWriteLogs = (Test-PathWritable -Path $LogsPath)
        canAccessDockerDaemon = $canAccessDockerDaemon
        canRunCompose = $canRunCompose
        canInspectServices = $true
        canManageServices = $isElevated
    }
    compatibilityHints = $compatibilityHints
}

$result | ConvertTo-Json -Depth 5

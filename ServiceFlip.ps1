param (
    [Parameter(Mandatory = $true)]
    [int]$Version
)

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

# ------------------------ LOGGING ------------------------

$LogPath = Join-Path $Root "logger.log"

# Ensure Logging file exists 
if (-not (Test-Path -Path $LogPath)) { New-Item -Path $LogPath -ItemType File | Out-Null }

function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] $Message"
    Add-Content -Path $LogPath -Value $entry
    Write-Output $entry
}

# ------------------------ CONFIG ------------------------

# Load from a configuration file 
$ConfigPath = "$Root\Config.json"

if (-not(Test-Path -Path $ConfigPath)) {
    Write-Log "Configuration file not found at $ConfigPath"
    exit 1 
}

$Config = Get-Content -Path $ConfigPath | ConvertFrom-Json

$Service = $Config.Service
$ServicePath = $Config.ServicePath
$VersionList = $Config.VersionList

# ------------------------ Version Mapping ------------------------
$VersionMap = @{}

Get-ChildItem -Path $ServicePath -Directory | ForEach-Object {
    $folderName = $_.Name

    # Match base folder for service (Service) and versioned folders (Service 202, etc.)
    if ($folderName -eq $Service -or $folderName -like "$Service *") { 
        $exePath = Join-Path $_.FullName "$Service.exe"

        if (Test-Path $exePath) {
            $fileVersion = (Get-Item $exePath).VersionInfo.FileVersion
            $majorVersion = [int]($fileVersion.Split('.')[0])

            if ($VersionList -contains $majorVersion) {
                $VersionMap[$majorVersion] = $_.FullName
            }
        }
    }
}

# Validate the requested version
if (-not $VersionMap.ContainsKey($Version)) {
    Write-Log "Version $Version not found or not recognised. Valid versions: $($VersionMap.Keys -join ', ')"
    exit 1
}

# Determine the current version folder (root version is unnumbered)
$CurrentRootPath = $VersionMap.Values | Where-Object { $_ -match "\\$Service$" }
if (-not $CurrentRootPath) {
    Write-Log "Could not determine the current running version for $Service"
    exit 1
}

$currentExe = Join-Path $CurrentRootPath "$Service.exe"
$currentFileVersion = (Get-Item $currentExe).VersionInfo.FileVersion
[int]$RunningVersion = $currentFileVersion.Split('.')[0]

if ($RunningVersion -eq $Version) {
    Write-Log "Already running version $RunningVersion"
    exit
}

# Prepare names for folder renaming
$DeactivatedVersionName = "$Service $RunningVersion"
$ActivatedVersionPath = $VersionMap[$Version]
$ActivatedVersionFolderName = Split-Path $ActivatedVersionPath -Leaf

# ------------------------ Service Flip ------------------------
try {
    Write-Log "Starting service flip..."
    Write-Log "Stopping service: $Service"
    Get-Service -DisplayName $Service | Stop-Service -Force -ErrorAction Stop
    Write-Log "Service stopped."

    Write-Log "Renaming root folder to: $DeactivatedVersionName"
    Rename-Item -Path $CurrentRootPath -NewName $DeactivatedVersionName -Force -ErrorAction Stop

    Write-Log "Renaming $ActivatedVersionFolderName to: $Service"
    Rename-Item -Path $ActivatedVersionPath -NewName $Service -Force -ErrorAction Stop

    Write-Log "Starting service: $Service"
    Get-Service -DisplayName $Service | Start-Service -ErrorAction Stop
    Write-Log "Service started."

    $msg = "Service flip complete. Now running version $Version"
    Write-Log $msg

} catch {
    $errorMsg = "ERROR during service flip: $_"
    Write-Log $errorMsg
    exit 1
}

param (
    [switch]$Flip
)

# ------------------------ CONFIG ------------------------
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

# Paths & service names
$Service = 'ServicePlaceholder'
$ServicePath = 'C:\Users\sjcul\OneDrive\Documents\PowerShellLearn\Testing\Services'
$Version202 = "$Service 202"
$Version212 = "$Service 212"

# Logging
$LogPath = "$Root\logger.log"
if (-not (Test-Path -Path $LogPath)) { New-Item -Path $LogPath -ItemType File | Out-Null }
# --------------------------------------------------------

function Write-Log {   
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] $Message"
    Add-Content -Path $LogPath -Value $entry
    Write-Output $entry
}

# Determine which version is becoming active
# If -Flip is used, swap to Version212, else to Version202

if ($Flip) {
    $CurrentVersion = $Service
    $UnRoot = $Version202
    $NewActive = $Version212
    if (-not (Test-Path -Path "$ServicePath\$Version212")) {
        Write-Log "Service flip triggered incorrectly, current service is already $Version212"
        exit
    }
} else {
    $CurrentVersion = $Service
    $UnRoot = $Version212
    $NewActive = $Version202
    if (-not (Test-Path -Path "$ServicePath\$Version202")) {
        Write-Log "Service flip triggered incorrectly, current service is already $Version202"
        exit
    }
}

try {
    Write-Log "Starting Service Flip "
    Write-Log "Stopping service: $Service"
    Get-Service -DisplayName $Service | Stop-Service -Force -ErrorAction Stop 
    Write-Log "Service stopped."

    # Changes the current version name so it is not the root version and have its version number in the name 
    Write-Log "Renaming $CurrentVersion -> $UnRoot"
    Rename-Item -Path "$ServicePath\$Service" -NewName $UnRoot -Force -ErrorAction Stop 

    # Does the opposite and makes the other the root 
    Write-Log "Renaming $NewActive -> $Service"
    Rename-Item -Path "$ServicePath\$NewActive" -NewName $Service -Force -ErrorAction Stop 

    Write-Log "Starting service: $Service"
    Get-Service -DisplayName $Service | Start-Service -ErrorAction Stop 
    Write-Log "Service started."

    $msg = "Service flip complete. Now running version: $NewActive"
    Write-Log $msg

} catch {
    $errorMsg = "ERROR during service flip: $_"
    Write-Log $errorMsg
    exit 1
}

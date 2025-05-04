param (
    [switch]$Flip
)

# ------------------------ CONFIG ------------------------
# Paths & service names
$Service = 'ServiceNamePlaceholder'
$ServicePath = 'C:\Path\To\Service'
$Version202 = "$Service 202"
$Version212 = "$Service 212"

# Logging
$LogPath = "C:\Logs\ServiceSwitch.log"
# --------------------------------------------------------

function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] $Message"
    Add-Content -Path $LogPath -Value $entry
    Write-Output $entry
}

# Determine which version is becoming active
# If -FLip is active then switch to 212 
if ($Flip) {
    $CurrentVersion = $Service
    $UnRoot = $Version202
    $NewActive = $Version212
} else {
    $CurrentVersion = $Service
    $UnRoot = $Version212
    $NewActive = $Version202
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

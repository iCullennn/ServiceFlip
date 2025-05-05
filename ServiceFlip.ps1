param (
    [Parameter(Mandatory = $true)]
    [int]$Version
)

# ------------------------ CONFIG ------------------------
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

# Paths & service names
$Service = 'ServicePlaceholder'
$ServicePath = 'C:\Users\sjcul\OneDrive\Documents\PowerShellLearn\Testing\Services'
#$Version202 = "$Service 202"
#$Version212 = "$Service 212"

# Declare an array of integers explicitly
[int[]]$VersionList = 202, 212

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

# Not used yet still trying to figure out the details for authentication 
function Send-Email {
    param (
        [string]$Subject,
        [string]$Body
    )

    $smtpClient = New-Object System.Net.Mail.SmtpClient("smtp.gmail.com", 587)
    $smtpClient.EnableSsl = $true
    $smtpClient.Credentials = New-Object System.Net.NetworkCredential("myemail@gmail.com", "Password")

    $mail = New-Object System.Net.Mail.MailMessage
    $mail.From = "myemail@gmail.com"
    $mail.To.Add("recipient@company.com")
    $mail.Subject = $Subject
    $mail.Body = $Body

    try {
        $smtpClient.Send($mail)
        Write-Output "Email sent successfully."
    } catch {
        Write-Output "Failed to send email: $_"
    }
}

# Check what current version is running 
# Assuming this works for now to check the .dll for the version 
$RunningVersion = (Get-Item "$ServicePath\$Service\service.dll").VersionInfo.FileVersion
if (-not $RunningVersion) { # If the above version info fails and returns NULL 
    Write-Log "Failed to retrieve service version from DLL"
    exit 1
}

[int]$RunningVersionInt = $RunningVersion.Split('.')[0] # Gets the interger of te version excluding any other info 

if ($VersionList -contains $Version) {
    if ($RunningVersionInt -eq $Version) {
        Write-Log "Already running version $RunningVersionInt"
        exit
    }

    $DeactivatedVersion = "$Service $RunningVersionInt"
    $ActivatedVersion = "$Service $Version"
} else {
    Write-Log "Version $Version not recognised. Valid versions: $($VersionList -join ', ')"
    exit 
}

<#
# OLD VERSION 
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
#>

try {
    Write-Log "Starting Service Flip "
    Write-Log "Stopping service: $Service"
    Get-Service -DisplayName $Service | Stop-Service -Force -ErrorAction Stop 
    Write-Log "Service stopped."

    # Changes the current version name so it is not the root version and have its version number in the name 
    Write-Log "Renaming $RunningVersion -> $DeactivatedVersion"
    Rename-Item -Path "$ServicePath\$Service" -NewName $DeactivatedVersion -Force -ErrorAction Stop 

    # Does the opposite and makes the other the root 
    Write-Log "Renaming $ActivatedVersion -> $Service"
    Rename-Item -Path "$ServicePath\$ActivatedVersion" -NewName $Service -Force -ErrorAction Stop 

    Write-Log "Starting service: $Service"
    Get-Service -DisplayName $Service | Start-Service -ErrorAction Stop 
    Write-Log "Service started."

    $msg = "Service flip complete. Now running version: $ActivatedVersion"
    Write-Log $msg

} catch {
    $errorMsg = "ERROR during service flip: $_"
    Write-Log $errorMsg
    exit 1
}

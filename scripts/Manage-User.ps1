param(
    [string]$Username,
    [string]$Password
)

$ErrorActionPreference = 'Stop'

Write-Host "--- Managing RDP User: $Username ---" -ForegroundColor Cyan

# Allow callers to pass the password via the RDP_PASS environment variable to
# avoid embedding secrets in the PowerShell command line (where they can be
# captured by process listings / ETW / transcript logs).
if ([string]::IsNullOrEmpty($Password) -and -not [string]::IsNullOrEmpty($env:RDP_PASS)) {
    $Password = $env:RDP_PASS
}

if ([string]::IsNullOrEmpty($Password)) {
    Write-Host "[ERROR] No password supplied: pass -Password or set RDP_PASS environment variable." -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($Username)) {
    Write-Host "[ERROR] Username is required." -ForegroundColor Red
    exit 1
}

$securePass = ConvertTo-SecureString $Password -AsPlainText -Force

try {
    if (-not (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {
        Write-Host "Creating new user $Username..."
        New-LocalUser -Name $Username -Password $securePass -AccountNeverExpires
        Add-LocalGroupMember -Group "Administrators" -Member $Username
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member $Username
        Write-Host "[SUCCESS] User account '$Username' deployed successfully." -ForegroundColor Green
    } else {
        Write-Host "Updating password for existing user $Username..."
        $user = Get-LocalUser -Name $Username
        $user | Set-LocalUser -Password $securePass
        Write-Host "[SUCCESS] Credentials updated for existing user '$Username'." -ForegroundColor Green
    }
}
catch {
    Write-Host "[ERROR] Failed to deploy/update user account '$Username'. Error: $_" -ForegroundColor Red
    if ($_.Exception -and $_.Exception.GetType().Name -eq "InvalidPasswordException") {
        Write-Host "[ERROR] This is likely due to the password not meeting Windows Server complexity requirements." -ForegroundColor Red
    }
    exit 1
}

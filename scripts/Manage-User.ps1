param(
    [string]$Username,
    [string]$Password
)

$ErrorActionPreference = 'Stop'

Write-Host "--- Managing RDP User: $Username ---" -ForegroundColor Cyan

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
    Write-Host "[WARNING] Failed to deploy/update user account '$Username'. Error: $_" -ForegroundColor Yellow
    if ($_.Exception -and $_.Exception.GetType().Name -eq "InvalidPasswordException") {
        Write-Host "[WARNING] This is likely due to the password not meeting Windows Server complexity requirements." -ForegroundColor Yellow
    }
    # We do not rethrow or exit with error to maintain backwards compatibility with the original workflow behavior
}

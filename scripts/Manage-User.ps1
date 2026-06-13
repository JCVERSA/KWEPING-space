param(
    [string]$Username,
    [string]$Password
)

$ErrorActionPreference = 'Stop'

Write-Host "--- Managing RDP User: $Username ---" -ForegroundColor Cyan

$securePass = ConvertTo-SecureString $Password -AsPlainText -Force

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

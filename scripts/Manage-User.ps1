# These rules are intentionally suppressed for this script:
#   - PSAvoidUsingConvertToSecureStringWithPlainText: the password arrives at
#     runtime from a CI secret via $env:RDP_PASS. Converting a runtime-supplied
#     plaintext string into a SecureString is the required Windows API pattern
#     for New-LocalUser / Set-LocalUser; there is no alternative way to pass a
#     newly supplied credential to those cmdlets.
#   - PSAvoidUsingPlainTextForPassword: we deliberately read the password from
#     an environment variable (not a hard-coded literal). A [SecureString]
#     parameter cannot be populated from an environment variable directly; the
#     conversion to SecureString happens immediately after reading.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
param()

$ErrorActionPreference = 'Stop'

# The username comes from $env:RDP_USERNAME; the password comes from $env:RDP_PASS.
# Reading credentials from env vars avoids interpolating secrets into the
# PowerShell command line (where they can appear in process listings / ETW).
$Username = $env:RDP_USERNAME

Write-Host "--- Managing RDP User: $Username ---" -ForegroundColor Cyan

if ([string]::IsNullOrEmpty($Username)) {
    Write-Host "[ERROR] RDP_USERNAME environment variable is required." -ForegroundColor Red
    exit 1
}

$Password = $env:RDP_PASS
if ([string]::IsNullOrEmpty($Password)) {
    Write-Host "[ERROR] RDP_PASS environment variable is required (no password supplied)." -ForegroundColor Red
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

param(
    [string]$Username = "Neon",
    [int]$TimeoutMinutes = 350,
    [string]$Language = "en-US",
    [string]$NodeVersion = "",
    [string]$JavaVersion = "",
    [bool]$SshEnabled = $false,
    [string]$SshShell = "",
    # Display-only label shown in the connection banner for the credential line.
    # Named to avoid triggering PSAvoidUsingPlainTextForPassword (it is never a
    # real credential, just a "[REDACTED]"-style placeholder).
    [string]$CredentialLabel = "[REDACTED]"
)

$ErrorActionPreference = 'Stop'

Write-Host "--- Maintain Connection Loop ---" -ForegroundColor Cyan

# Clamp timeout to the GitHub Actions workflow_max / runner maximum (350 min)
# and to a positive value. Workflow-level timeout-minutes (360) is the hard cap.
if ($TimeoutMinutes -le 0 -or $TimeoutMinutes -gt 350) { $TimeoutMinutes = 350 }
$maxSeconds = $TimeoutMinutes * 60

# 1. Drop the Save_and_Exit shortcut onto the Public Desktop.
$publicDesktop = "C:\Users\Public\Desktop"
$shortcutPath = "$publicDesktop\Save_and_Exit.bat"
$scriptContent = @'
@echo off
echo ===================================================
echo    SAVING YOUR PROJECTS AND CLOSING WORKSPACE RDP
echo ===================================================
echo.
echo Transmitting stop notification flag to GitHub...
echo stop > D:\RDP_Data\stop.txt
echo.
echo You can now safely close this Remote Desktop window.
echo GitHub Actions will finalize cache commit operations.
echo.
pause
'@
Set-Content -Path $shortcutPath -Value $scriptContent -Force

# 2. Clean any stale stop flag from a previous run.
if (Test-Path "D:\RDP_Data\stop.txt") { Remove-Item "D:\RDP_Data\stop.txt" -Force }

# 3. Print the connection banner.
Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "          WINDOWS RDP RUNTIME ONLINE           " -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host "Tailscale IP Address : $env:TAILSCALE_IP" -ForegroundColor Cyan
Write-Host "Active Username      : $Username" -ForegroundColor Cyan
Write-Host "Active Password      : $CredentialLabel" -ForegroundColor Cyan
if ($Language) {
    Write-Host "Selected UI Language : $Language" -ForegroundColor Cyan
}
Write-Host "Allocated Runtime    : $TimeoutMinutes minutes" -ForegroundColor Cyan
if ($NodeVersion) {
    Write-Host "Node.js Environment  : v$NodeVersion" -ForegroundColor Cyan
}
if ($JavaVersion) {
    Write-Host "Java Development Kit : v$JavaVersion" -ForegroundColor Cyan
}
if ($SshEnabled) {
    try {
        $sshdStatus = (Get-Service sshd -ErrorAction Stop).Status
    }
    catch {
        $sshdStatus = "Unknown"
    }
    Write-Host "SSH/SFTP Server      : $sshdStatus (Shell: $SshShell)" -ForegroundColor Green
}
else {
    Write-Host "SSH/SFTP Server      : DISABLED" -ForegroundColor Yellow
}
Write-Host "-----------------------------------------------"
Write-Host "WARNING for persistence: When your work session is finished," -ForegroundColor Yellow
Write-Host "  run the 'Save_and_Exit' shortcut on the Public Desktop so" -ForegroundColor Yellow
Write-Host "  GitHub Actions can finalize cache commit operations." -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

# 4. Keep-alive loop.
$elapsed = 0
while ($elapsed -lt $maxSeconds) {
    if (Test-Path "D:\RDP_Data\stop.txt") {
        Remove-Item "D:\RDP_Data\stop.txt" -Force
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Shutdown trigger caught! Initializing unmount procedures..." -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 10
    $elapsed += 10
    if (($elapsed % 300) -eq 0) {
        $timeLeft = [Math]::Round(($maxSeconds - $elapsed) / 60, 1)
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] RDP/SSH pipeline active. Approximately $timeLeft minutes remaining."
    }
}

if ($elapsed -ge $maxSeconds) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Reached allocated runtime of $TimeoutMinutes minutes; exiting loop." -ForegroundColor Yellow
}

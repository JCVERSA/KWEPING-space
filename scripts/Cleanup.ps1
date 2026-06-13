$ErrorActionPreference = 'Continue'

Write-Host "--- Cleaning up processes and releasing file locks ---" -ForegroundColor Cyan

$processes = @("sshd", "firefox", "Code", "node", "java", "studio64", "adb")

foreach ($proc in $processes) {
    if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
        Write-Host "Stopping $proc..."
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
    }
}

Start-Sleep -Seconds 5
Write-Host "Cleanup complete. File locks should be released." -ForegroundColor Green

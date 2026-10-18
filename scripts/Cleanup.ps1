$ErrorActionPreference = 'Continue'

Write-Host "--- Cleaning up processes and releasing file locks ---" -ForegroundColor Cyan

# Processes that commonly hold files open inside D:\RDP_Data caches; we stop
# them gracefully before the post step saves caches so locked files don't
# cause cache-save failures.
$processes = @("sshd", "firefox", "Code", "node", "java", "studio64", "adb")

foreach ($proc in $processes) {
    $procs = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($procs) {
        Write-Host "Stopping $proc ($(@($procs).Count) instance(s))..."
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}

# Give the OS a moment to release file handles (cache save happens immediately
# after this step returns when used in a GitHub Actions post step).
Start-Sleep -Seconds 8
Write-Host "Cleanup complete. File locks should be released." -ForegroundColor Green

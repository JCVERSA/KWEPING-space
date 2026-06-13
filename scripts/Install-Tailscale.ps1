param(
    [string]$AuthKey,
    [string]$Hostname
)

$ErrorActionPreference = 'Stop'

Write-Host "--- Installing Tailscale ---" -ForegroundColor Cyan

$tsUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi"
$installerPath = "$env:TEMP\tailscale.msi"

Write-Host "Downloading Tailscale..."
Invoke-WebRequest -Uri $tsUrl -OutFile $installerPath

Write-Host "Installing Tailscale MSI..."
$process = Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    Write-Host "[ERROR] Tailscale installation failed with exit code $($process.ExitCode)" -ForegroundColor Red
    exit 1
}
Remove-Item $installerPath -Force

if ($AuthKey) {
    Write-Host "Establishing Tailscale Connection..."
    & "$env:ProgramFiles\Tailscale\tailscale.exe" up --authkey=$AuthKey --hostname=$Hostname

    $tsIP = $null
    $retries = 0
    while (-not $tsIP -and $retries -lt 12) {
        Start-Sleep -Seconds 5
        $tsIP = (& "$env:ProgramFiles\Tailscale\tailscale.exe" ip -4).Trim()
        $retries++
    }

    if (-not $tsIP) {
        Write-Host "[ERROR] Failed to obtain Tailscale IP address." -ForegroundColor Red
        exit 1
    }

    Write-Host "Tailscale IP: $tsIP" -ForegroundColor Green
    # Output to GitHub Env if running in GitHub Actions
    if ($env:GITHUB_ENV) {
        "TAILSCALE_IP=$tsIP" | Out-File -FilePath $env:GITHUB_ENV -Append
    }
}

param(
    [string]$AuthKey,
    [string]$Hostname,
    [string]$Version = "1.82.0",
    [string]$ExpectedSha256 = ""
)

$ErrorActionPreference = 'Stop'

Write-Host "--- Installing Tailscale v$Version ---" -ForegroundColor Cyan

# Allow credentials to come from environment variables so they are not
# interpolated into the workflow YAML source / PowerShell command line.
if ([string]::IsNullOrEmpty($AuthKey) -and -not [string]::IsNullOrEmpty($env:TAILSCALE_AUTH_KEY)) {
    $AuthKey = $env:TAILSCALE_AUTH_KEY
}
if ([string]::IsNullOrEmpty($Hostname) -and -not [string]::IsNullOrEmpty($env:TAILSCALE_HOSTNAME)) {
    $Hostname = $env:TAILSCALE_HOSTNAME
}

$tsUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-$Version-amd64.msi"
$installerPath = Join-Path $env:TEMP "tailscale-$Version.msi"

Write-Host "Downloading Tailscale from $tsUrl ..."
Invoke-WebRequest -Uri $tsUrl -OutFile $installerPath

# Integrity check (optional but recommended): if ExpectedSha256 is provided,
# verify the MSI matches before running msiexec. This guards against a
# compromised CDN or a silently replaced download.
if (-not [string]::IsNullOrEmpty($ExpectedSha256)) {
    $actualHash = (Get-FileHash -Path $installerPath -Algorithm SHA256).Hash
    if ($actualHash -ne $ExpectedSha256) {
        Write-Host "[ERROR] Tailscale MSI hash mismatch." -ForegroundColor Red
        Write-Host "  Expected: $ExpectedSha256" -ForegroundColor Red
        Write-Host "  Actual  : $actualHash" -ForegroundColor Red
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        exit 1
    }
    Write-Host "[VERIFIED] Tailscale MSI SHA-256 matches expected value." -ForegroundColor Green
}
else {
    Write-Host "[WARNING] No ExpectedSha256 provided; skipping MSI integrity verification." -ForegroundColor Yellow
}

Write-Host "Installing Tailscale MSI..."
$process = Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    Write-Host "[ERROR] Tailscale installation failed with exit code $($process.ExitCode)" -ForegroundColor Red
    exit 1
}
Remove-Item $installerPath -Force -ErrorAction SilentlyContinue

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
    # Output to GitHub Env if running in GitHub Actions using robust UTF-8/No-BOM method
    if ($env:GITHUB_ENV) {
        [System.IO.File]::AppendAllLines($env:GITHUB_ENV, [string[]]@("TAILSCALE_IP=$tsIP"))
        Write-Host "[INFO] Appended TAILSCALE_IP to GITHUB_ENV." -ForegroundColor Cyan
    }
}

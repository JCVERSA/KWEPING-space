$ErrorActionPreference = 'Stop'

Write-Host "--- Configuring RDP ---" -ForegroundColor Cyan

try {
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0 -Force
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0 -Force
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "SecurityLayer" -Value 0 -Force
}
catch {
    Write-Host "[WARNING] Non-critical RDP registry configuration warning: $_" -ForegroundColor Yellow
}

# Port 3389 open only for Tailscale IP range
try {
    Write-Host "Configuring firewall for RDP (Tailscale range)..."
    netsh advfirewall firewall delete rule name="RDP-Tailscale" 2>$null
    netsh advfirewall firewall add rule name="RDP-Tailscale" dir=in action=allow protocol=TCP localport=3389 remoteip=100.64.0.0/10
}
catch {
    Write-Host "[WARNING] Non-critical RDP firewall configuration warning: $_" -ForegroundColor Yellow
}

try {
    Write-Host "Restarting TermService..."
    Restart-Service -Name TermService -Force
}
catch {
    Write-Host "[WARNING] Non-critical TermService restart warning: $_" -ForegroundColor Yellow
}

Write-Host "[SUCCESS] RDP configured." -ForegroundColor Green

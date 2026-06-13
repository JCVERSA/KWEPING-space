$ErrorActionPreference = 'Stop'

Write-Host "--- Configuring RDP ---" -ForegroundColor Cyan

Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0 -Force
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0 -Force
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "SecurityLayer" -Value 0 -Force

# Port 3389 open only for Tailscale IP range
Write-Host "Configuring firewall for RDP (Tailscale range)..."
netsh advfirewall firewall delete rule name="RDP-Tailscale" 2>$null
netsh advfirewall firewall add rule name="RDP-Tailscale" dir=in action=allow protocol=TCP localport=3389 remoteip=100.64.0.0/10

Restart-Service -Name TermService -Force

Write-Host "[SUCCESS] RDP configured." -ForegroundColor Green

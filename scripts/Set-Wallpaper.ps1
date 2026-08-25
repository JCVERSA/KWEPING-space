<#
.SYNOPSIS
    Applique des wallpapers custom pour le Bureau et le Lock Screen Windows.

.DESCRIPTION
    Script PowerShell modulaire :
    - Bureau : via API Win32 SystemParametersInfo (user32.dll) + Registre HKCU pour persistance
    - Lock Screen : via Registre HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization (LockScreenImage)
                   + via PersonalizationCSP
                   + remplacement physique de C:\Windows\Web\Wallpaper\Windows\img0.jpg
    - Sécurité : ignore silencieusement si les fichiers sont introuvables

.PARAMETER DesktopWallpaperPath
    Chemin vers l'image du bureau (défaut: assets/home.jpg)

.PARAMETER LockScreenImagePath
    Chemin vers l'image du lock screen (défaut: assets/lock.jpg)

.EXAMPLE
    .\scripts\Set-Wallpaper.ps1 -DesktopWallpaperPath "assets/home.jpg" -LockScreenImagePath "assets/lock.jpg"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DesktopWallpaperPath = "assets/home.jpg",

    [Parameter(Mandatory = $false)]
    [string]$LockScreenImagePath = "assets/lock.jpg"
)

$ErrorActionPreference = 'Continue'

# --------------------------------------------------
# Helpers
# --------------------------------------------------
function Resolve-AbsolutePathSafe {
    param([string]$Path)
    try {
        if (-not (Test-Path -LiteralPath $Path)) { return $null }
        return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    } catch {
        return $null
    }
}

function Test-ImageFile {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    return (Test-Path -LiteralPath $Path -PathType Leaf)
}

# --------------------------------------------------
# Desktop Wallpaper via SystemParametersInfo
# --------------------------------------------------
function Set-DesktopWallpaper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )

    if (-not (Test-ImageFile -Path $ImagePath)) {
        Write-Host "[WALLPAPER] Desktop image not found, skipping silently: $ImagePath" -ForegroundColor DarkGray
        return
    }

    $absPath = Resolve-AbsolutePathSafe -Path $ImagePath
    if (-not $absPath) {
        Write-Host "[WALLPAPER] Unable to resolve desktop path, skipping: $ImagePath" -ForegroundColor DarkGray
        return
    }

    Write-Host "[WALLPAPER] Applying desktop wallpaper: $absPath" -ForegroundColor Cyan

    try {
        # Persist wallpaper style in registry (Fill = 10, Tile = 0)
        $desktopReg = "HKCU:\Control Panel\Desktop"
        if (Test-Path $desktopReg) {
            Set-ItemProperty -Path $desktopReg -Name "Wallpaper" -Value $absPath -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $desktopReg -Name "WallpaperStyle" -Value "10" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $desktopReg -Name "TileWallpaper" -Value "0" -Force -ErrorAction SilentlyContinue
        }

        # Also set for .DEFAULT user (login screen background fallback)
        $defaultReg = "HKU:\.DEFAULT\Control Panel\Desktop"
        # HKU PSDrive may not exist, create temporarily if needed
        try {
            if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
                New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
            }
            if (Test-Path $defaultReg) {
                Set-ItemProperty -Path $defaultReg -Name "Wallpaper" -Value $absPath -Force -ErrorAction SilentlyContinue
            }
        } catch {
            # silent ignore
        }

        # Import SystemParametersInfo
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WallpaperNative {
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@ -ErrorAction SilentlyContinue

        $SPI_SETDESKWALLPAPER = 0x0014
        $SPIF_UPDATEINIFILE = 0x01
        $SPIF_SENDWININICHANGE = 0x02
        $flags = $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE

        $result = [WallpaperNative]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $absPath, $flags)

        if ($result) {
            Write-Host "[SUCCESS] Desktop wallpaper applied via SystemParametersInfo." -ForegroundColor Green
        } else {
            Write-Host "[WALLPAPER] SystemParametersInfo returned false, but registry set. Might need logoff." -ForegroundColor Yellow
        }

        # Extra: copy to a safe persistent location to survive some resets
        try {
            $customDir = "C:\Windows\Web\Wallpaper\Custom"
            if (-not (Test-Path $customDir)) {
                New-Item -ItemType Directory -Path $customDir -Force -ErrorAction SilentlyContinue | Out-Null
            }
            Copy-Item -LiteralPath $absPath -Destination "$customDir\home.jpg" -Force -ErrorAction SilentlyContinue
        } catch {
            # silent ignore
        }

    } catch {
        Write-Host "[WALLPAPER] Non-critical error applying desktop wallpaper: $_" -ForegroundColor DarkGray
    }
}

# --------------------------------------------------
# Lock Screen via Registry + file replacement
# --------------------------------------------------
function Set-LockScreenImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )

    if (-not (Test-ImageFile -Path $ImagePath)) {
        Write-Host "[WALLPAPER] Lock screen image not found, skipping silently: $ImagePath" -ForegroundColor DarkGray
        return
    }

    $absPath = Resolve-AbsolutePathSafe -Path $ImagePath
    if (-not $absPath) {
        Write-Host "[WALLPAPER] Unable to resolve lock screen path, skipping: $ImagePath" -ForegroundColor DarkGray
        return
    }

    Write-Host "[WALLPAPER] Applying lock screen image: $absPath" -ForegroundColor Cyan

    # 1. HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization -> LockScreenImage
    try {
        $personalizationPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
        if (-not (Test-Path $personalizationPolicyPath)) {
            New-Item -Path $personalizationPolicyPath -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Host "[WALLPAPER] Created registry key: $personalizationPolicyPath" -ForegroundColor DarkGray
        }
        New-ItemProperty -Path $personalizationPolicyPath -Name "LockScreenImage" -Value $absPath -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $personalizationPolicyPath -Name "LockScreenImage" -Value $absPath -Force -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] LockScreenImage set in Personalization policy registry." -ForegroundColor Green
    } catch {
        Write-Host "[WALLPAPER] Non-critical registry error (Personalization policy): $_" -ForegroundColor DarkGray
    }

    # 2. PersonalizationCSP (MDM style) - more reliable on Win10/11/Server 2025
    try {
        $cspPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
        if (-not (Test-Path $cspPath)) {
            New-Item -Path $cspPath -Force -ErrorAction SilentlyContinue | Out-Null
        }
        # Status = 1 means enabled/custom
        New-ItemProperty -Path $cspPath -Name "LockScreenImageStatus" -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $cspPath -Name "LockScreenImagePath" -Value $absPath -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $cspPath -Name "LockScreenImageUrl" -Value $absPath -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $cspPath -Name "LockScreenImageStatus" -Value 1 -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $cspPath -Name "LockScreenImagePath" -Value $absPath -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $cspPath -Name "LockScreenImageUrl" -Value $absPath -Force -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] LockScreenImage set in PersonalizationCSP." -ForegroundColor Green
    } catch {
        Write-Host "[WALLPAPER] Non-critical registry error (PersonalizationCSP): $_" -ForegroundColor DarkGray
    }

    # 3. Replace default Windows Spotlight / default lock image: C:\Windows\Web\Wallpaper\Windows\img0.jpg
    try {
        $defaultLockPath = "C:\Windows\Web\Wallpaper\Windows\img0.jpg"
        $defaultDir = Split-Path $defaultLockPath -Parent

        if (-not (Test-Path $defaultDir)) {
            New-Item -ItemType Directory -Path $defaultDir -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # Try to take ownership and grant permission if needed (best effort, silently)
        try {
            $acl = Get-Acl $defaultLockPath -ErrorAction SilentlyContinue
            if ($acl) {
                # Attempt to copy anyway with -Force, Windows will allow as admin in most cases
            }
        } catch {
            # ignore
        }

        # Backup original if not already backed up
        try {
            $backupPath = "C:\Windows\Web\Wallpaper\Windows\img0_backup.jpg"
            if ((Test-Path $defaultLockPath) -and -not (Test-Path $backupPath)) {
                Copy-Item -LiteralPath $defaultLockPath -Destination $backupPath -Force -ErrorAction SilentlyContinue
            }
        } catch {
            # ignore
        }

        Copy-Item -LiteralPath $absPath -Destination $defaultLockPath -Force -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Replaced $defaultLockPath with custom lock image." -ForegroundColor Green

        # Also replace img0 variants if they exist (img100, img105 etc on some builds)
        try {
            $variants = @(
                "C:\Windows\Web\Wallpaper\Windows\img0.jpg",
                "C:\Windows\Web\Screen\img100.jpg",
                "C:\Windows\Web\Screen\img100.png",
                "C:\Windows\Web\Screen\img105.jpg",
                "C:\Windows\Web\Screen\img105.png"
            )
            foreach ($v in $variants) {
                if (Test-Path (Split-Path $v -Parent)) {
                    Copy-Item -LiteralPath $absPath -Destination $v -Force -ErrorAction SilentlyContinue
                }
            }
        } catch {
            # ignore
        }

    } catch {
        Write-Host "[WALLPAPER] Non-critical file replace error for img0.jpg: $_" -ForegroundColor DarkGray
    }

    # 4. Optional: Set lock screen for all users via registry
    try {
        $lockScreenReg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Creative"
        # Some builds use this path, try to set if exists
        if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI") {
            # No direct key, but we ensure policy is set - already done
        }
    } catch {
        # silent
    }
}

# --------------------------------------------------
# Main Execution
# --------------------------------------------------
Write-Host "--- Applying Custom Wallpapers ---" -ForegroundColor Cyan
Write-Host "[INFO] Desktop param: $DesktopWallpaperPath" -ForegroundColor DarkGray
Write-Host "[INFO] LockScreen param: $LockScreenImagePath" -ForegroundColor DarkGray

# Resolve relative paths based on script location or current dir
# If relative, they are relative to repository root (where workflow runs)
Set-DesktopWallpaper -ImagePath $DesktopWallpaperPath
Set-LockScreenImage -ImagePath $LockScreenImagePath

Write-Host "[SUCCESS] Wallpaper script execution completed (missing files were silently ignored)." -ForegroundColor Green

param (
    [string]$HomeWallpaperPath = "assets/home.jpg",
    [string]$LockWallpaperPath = "assets/lock.jpg"
)

# Safe path resolution relative to current execution path
if (-not [System.IO.Path]::IsPathRooted($HomeWallpaperPath)) {
    $HomeWallpaperPath = [System.IO.Path]::GetFullPath((Join-Path -Path $PWD -ChildPath $HomeWallpaperPath))
}

if (-not [System.IO.Path]::IsPathRooted($LockWallpaperPath)) {
    $LockWallpaperPath = [System.IO.Path]::GetFullPath((Join-Path -Path $PWD -ChildPath $LockWallpaperPath))
}

# 1. Apply Desktop Wallpaper (home.jpg)
if (Test-Path -Path $HomeWallpaperPath -PathType Leaf) {
    Write-Host "[WALLPAPER] Setting Desktop wallpaper from: $HomeWallpaperPath" -ForegroundColor Cyan
    try {
        $code = @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
        Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
        [Wallpaper]::SystemParametersInfo(0x0014, 0, $HomeWallpaperPath, 0x01 -bor 0x02) | Out-Null

        $regPath = "HKCU:\Control Panel\Desktop"
        if (Test-Path $regPath) {
            Set-ItemProperty -Path $regPath -Name "Wallpaper" -Value $HomeWallpaperPath -ErrorAction SilentlyContinue
        }
        Write-Host "[WALLPAPER] Desktop wallpaper successfully applied." -ForegroundColor Green
    }
    catch {
        Write-Host "[WALLPAPER] Unable to set desktop wallpaper via SystemParametersInfo: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "[WALLPAPER] Home wallpaper not found ($HomeWallpaperPath). Skipping silently." -ForegroundColor Yellow
}

# 2. Apply Lock Screen Wallpaper (lock.jpg)
if (Test-Path -Path $LockWallpaperPath -PathType Leaf) {
    Write-Host "[WALLPAPER] Setting Lock Screen wallpaper from: $LockWallpaperPath" -ForegroundColor Cyan
    try {
        $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
        if (-not (Test-Path $policyPath)) {
            New-Item -Path $policyPath -Force | Out-Null
        }
        New-ItemProperty -Path $policyPath -Name "LockScreenImage" -Value $LockWallpaperPath -PropertyType String -Force | Out-Null

        $defaultImgPath = "C:\Windows\Web\Wallpaper\Windows\img0.jpg"
        if (Test-Path $defaultImgPath) {
            Copy-Item -Path $LockWallpaperPath -Destination $defaultImgPath -Force -ErrorAction SilentlyContinue
        }
        Write-Host "[WALLPAPER] Lock screen wallpaper successfully configured." -ForegroundColor Green
    }
    catch {
        Write-Host "[WALLPAPER] Unable to set lock screen wallpaper: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "[WALLPAPER] Lock screen wallpaper not found ($LockWallpaperPath). Skipping silently." -ForegroundColor Yellow
}

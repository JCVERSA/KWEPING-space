param(
    [string]$RdpLanguage = "en-US"
)

$ErrorActionPreference = 'Stop'

Write-Host "--- Initializing Environment ---" -ForegroundColor Cyan

# 1. Verify Drive D
if (-not (Test-Path "D:")) {
    Write-Host "[ERROR] Drive D: is not available. Persistence cannot be guaranteed." -ForegroundColor Red
    exit 1
}

# 2. Structure Initialization on D:
$dirs = @(
    "D:\RDP_Data",
    "D:\RDP_Data\Projects",
    "D:\RDP_Data\FirefoxProfile",
    "D:\RDP_Data\AndroidConfig\.android",
    "D:\RDP_Data\AndroidConfig\.AndroidStudio",
    "D:\RDP_Data\AndroidConfig\.gradle"
)
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
    }
}

# 3. System Language Configuration
Write-Host "[LANG] Configuring system language to: $RdpLanguage" -ForegroundColor Cyan

Set-WinSystemLocale -SystemLocale $RdpLanguage
Set-WinUserLanguageList -LanguageList $RdpLanguage -Force

if ($RdpLanguage -eq "fr-FR") {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language" -Name "InstallLanguage" -Value "040c" -Force
    Set-WinHomeLocation -GeoId 84
} elseif ($RdpLanguage -eq "es-ES") {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language" -Name "InstallLanguage" -Value "0c0a" -Force
    Set-WinHomeLocation -GeoId 217
} else {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language" -Name "InstallLanguage" -Value "0409" -Force
    Set-WinHomeLocation -GeoId 244
}

# 4. Enforce persistent environment structures
[Environment]::SetEnvironmentVariable("GRADLE_USER_HOME", "D:\RDP_Data\AndroidConfig\.gradle", "Machine")
[Environment]::SetEnvironmentVariable("ANDROID_USER_HOME", "D:\RDP_Data\AndroidConfig\.android", "Machine")
[Environment]::SetEnvironmentVariable("ANDROID_EMULATOR_HOME", "D:\RDP_Data\AndroidConfig\.android", "Machine")

Write-Host "[SUCCESS] Environment initialization complete." -ForegroundColor Green

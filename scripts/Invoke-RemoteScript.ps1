param(
    [Parameter(Mandatory = $true)]
    [string]$Uri,
    [string]$ExpectedSha256 = "",
    [string]$Description = "remote script"
)

$ErrorActionPreference = 'Stop'

$tempFile = Join-Path $env:TEMP ("remote-" + [Guid]::NewGuid().ToString("N") + ".ps1")

try {
    Write-Host "[FETCH] Downloading ${Description}: $Uri" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $Uri -OutFile $tempFile -UseBasicParsing

    if (-not [string]::IsNullOrEmpty($ExpectedSha256)) {
        $actual = (Get-FileHash -Path $tempFile -Algorithm SHA256).Hash
        if ($actual -ne $ExpectedSha256) {
            Write-Host "[ERROR] Hash mismatch for ${Description}." -ForegroundColor Red
            Write-Host "  Expected: $ExpectedSha256" -ForegroundColor Red
            Write-Host "  Actual  : $actual" -ForegroundColor Red
            exit 1
        }
        Write-Host "[VERIFIED] ${Description} SHA-256 matches." -ForegroundColor Green
    }
    else {
        Write-Host "[WARNING] No ExpectedSha256 supplied for ${Description}; running without hash verification." -ForegroundColor Yellow
    }

    Write-Host "[EXEC] Running ${Description}..." -ForegroundColor Cyan
    & $tempFile
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] ${Description} exited with code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}
finally {
    if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
}

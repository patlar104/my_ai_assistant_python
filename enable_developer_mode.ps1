# Script to enable Developer Mode on Windows for Flutter
# This script must be run as Administrator

Write-Host "Enabling Developer Mode for Flutter..." -ForegroundColor Cyan

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternatively, you can enable Developer Mode manually:" -ForegroundColor Yellow
    Write-Host "1. Press Windows + I to open Settings" -ForegroundColor Yellow
    Write-Host "2. Go to Privacy & Security > For developers" -ForegroundColor Yellow
    Write-Host "3. Turn on 'Developer Mode'" -ForegroundColor Yellow
    exit 1
}

try {
    # Create the registry key if it doesn't exist
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    
    # Enable Developer Mode
    Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force
    
    Write-Host "✓ Developer Mode enabled successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You may need to restart your terminal or IDE for the changes to take effect." -ForegroundColor Yellow
    Write-Host "After restarting, try running 'flutter run -d windows' again." -ForegroundColor Yellow
} catch {
    Write-Host "ERROR: Failed to enable Developer Mode: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please enable Developer Mode manually:" -ForegroundColor Yellow
    Write-Host "1. Press Windows + I to open Settings" -ForegroundColor Yellow
    Write-Host "2. Go to Privacy & Security > For developers" -ForegroundColor Yellow
    Write-Host "3. Turn on 'Developer Mode'" -ForegroundColor Yellow
    exit 1
}




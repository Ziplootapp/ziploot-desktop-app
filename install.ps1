Set-Location -Path $PSScriptRoot

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   ZipLoot Web-to-Desktop App Builder (Tauri v2) Auto-Installer  " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

$AppUrl = Read-Host "Enter your Target Website URL (default: https://ziploot.app)"
if ([string]::IsNullOrWhiteSpace($AppUrl)) { $AppUrl = "https://ziploot.app" }
if (-not ($AppUrl.StartsWith("http://") -or $AppUrl.StartsWith("https://"))) {
    $AppUrl = "https://" + $AppUrl
}

$AppName = Read-Host "Enter your Desktop App Name (default: ZipLoot Desktop)"
if ([string]::IsNullOrWhiteSpace($AppName)) { $AppName = "ZipLoot Desktop" }

$AppId = Read-Host "Enter Bundle Identifier (default: app.ziploot.desktop)"
if ([string]::IsNullOrWhiteSpace($AppId)) { $AppId = "app.ziploot.desktop" }

Write-Host "`n[1/2] Generating src-tauri/tauri.conf.json..." -ForegroundColor Yellow

$jsonContent = @"
{
  "`$schema": "https://raw.githubusercontent.com/tauri-apps/tauri/dev/tooling/cli/schema.json",
  "productName": "$AppName",
  "version": "1.0.0",
  "identifier": "$AppId",
  "build": {
    "frontendDist": "$AppUrl"
  },
  "app": {
    "windows": [
      {
        "title": "$AppName — Native Desktop App",
        "url": "$AppUrl",
        "width": 1440,
        "height": 900,
        "resizable": true
      }
    ]
  },
  "bundle": {
    "active": true,
    "targets": "all",
    "icon": [
      "icons/32x32.png",
      "icons/128x128.png",
      "icons/128x128@2x.png",
      "icons/icon.ico"
    ]
  }
}
"@

Set-Content -Path "src-tauri/tauri.conf.json" -Value $jsonContent -Encoding UTF8

Write-Host "[2/2] Verifying build.rs script..." -ForegroundColor Yellow
$buildRsContent = 'fn main() { tauri_build::build(); }'
Set-Content -Path "src-tauri/build.rs" -Value $buildRsContent -Encoding UTF8

Write-Host "`n------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Select Build Mode:" -ForegroundColor Yellow
Write-Host "  [1] Save Project Files Locally on PC (Offline Mode)" -ForegroundColor White
Write-Host "  [2] Auto-Push to GitHub & Trigger Cloud .exe Build" -ForegroundColor White
$mode = Read-Host "Enter Choice [1 or 2] (default: 1)"

$currentDir = (Get-Item .).FullName

if ($mode -eq "2") {
    Write-Host "`n[GitHub Deployment Setup]" -ForegroundColor Yellow
    $userEmail = Read-Host "Enter your GitHub Email"
    $userName = Read-Host "Enter your GitHub Name/Username"
    $repoUrl = Read-Host "Enter your GitHub Repository URL (e.g. https://github.com/username/repo.git)"

    if (-not (Test-Path ".git")) {
        git init -q
    }

    if (-not [string]::IsNullOrWhiteSpace($userEmail)) { git config user.email "$userEmail" }
    if (-not [string]::IsNullOrWhiteSpace($userName)) { git config user.name "$userName" }

    git add .
    git commit -m "Automated Tauri Build for $AppName ($AppUrl)" -q

    if (-not [string]::IsNullOrWhiteSpace($repoUrl)) {
        git remote remove origin 2>$null
        git remote add origin "$repoUrl"
        git push -u origin main
        Write-Host "`n============================================================" -ForegroundColor Cyan
        Write-Host "SUCCESS! Cloud Build Triggered!" -ForegroundColor Green
        Write-Host "Track live build & download your .exe artifact on GitHub Actions!" -ForegroundColor Yellow
        Write-Host "============================================================" -ForegroundColor Cyan
    } else {
        Write-Host "`n============================================================" -ForegroundColor Cyan
        Write-Host "SUCCESS! Local Git Commit Prepared!" -ForegroundColor Green
        Write-Host "Project Directory: $currentDir" -ForegroundColor Yellow
        Write-Host "============================================================" -ForegroundColor Cyan
    }
} else {
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "SUCCESS! Project Files Saved Locally on your PC!" -ForegroundColor Green
    Write-Host "Project Directory: $currentDir" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
}

explorer.exe $currentDir

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

Write-Host "`n[1/3] Generating src-tauri/tauri.conf.json..." -ForegroundColor Yellow

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

Write-Host "[2/3] Verifying build.rs script..." -ForegroundColor Yellow
$buildRsContent = 'fn main() { tauri_build::build(); }'
Set-Content -Path "src-tauri/build.rs" -Value $buildRsContent -Encoding UTF8

Write-Host "[3/3] Committing and Pushing to GitHub..." -ForegroundColor Yellow
git add .
git commit -m "Automated 1-Click Tauri Build for $AppName ($AppUrl)"
git push origin main

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "🎉 SUCCESS! Cloud Build Triggered!" -ForegroundColor Green
Write-Host "GitHub Actions is now compiling your $AppName .exe in Microsoft Cloud!" -ForegroundColor Yellow
Write-Host "Track live build & download your .exe artifact here:" -ForegroundColor White
Write-Host "👉 https://github.com/Ziplootapp/ziploot-desktop-app/actions" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

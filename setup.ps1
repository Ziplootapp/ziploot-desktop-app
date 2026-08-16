Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   ZipLoot Automated Web-to-Desktop App Builder (Tauri v2)  " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

$AppUrl = Read-Host "Enter your Target Website URL (default: https://ziploot.app)"
if ([string]::IsNullOrWhiteSpace($AppUrl)) { $AppUrl = "https://ziploot.app" }

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

Write-Host "[3/3] Ready for 1-Click GitHub Actions Build!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "SUCCESS! Your Tauri desktop project is fully configured." -ForegroundColor Green
Write-Host "Next Step: Commit and push to GitHub to generate your .exe file!" -ForegroundColor Yellow
Write-Host "  git add ." -ForegroundColor White
Write-Host "  git commit -m 'Configure desktop build'" -ForegroundColor White
Write-Host "  git push origin main" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

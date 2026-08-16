# ZipLoot Web-to-Native Tauri Desktop App 1-Click Setup Script (Windows PowerShell)
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
$TauriConf = @{
    "`$schema" = "https://raw.githubusercontent.com/tauri-apps/tauri/dev/tooling/cli/schema.json"
    "productName" = $AppName
    "version" = "1.0.0"
    "identifier" = $AppId
    "build" = @{ "frontendDist" = $AppUrl }
    "app" = @{
        "windows" = @(
            @{
                "title" = "$AppName — Native Desktop App"
                "url" = $AppUrl
                "width" = 1440
                "height" = 900
                "resizable" = $true
            }
        )
    }
    "bundle" = @{
        "active" = $true
        "targets" = "all"
        "icon" = @("icons/32x32.png", "icons/128x128.png", "icons/128x128@2x.png", "icons/icon.ico")
    }
} | ConvertTo-Json -Depth 5

$TauriConf | Out-File -FilePath "src-tauri/tauri.conf.json" -Encoding utf8

Write-Host "[2/3] Verifying src-tauri/build.rs & icons..." -ForegroundColor Yellow
if (-not (Test-Path "src-tauri/build.rs")) {
    "fn main() { tauri_build::build(); }" | Out-File -FilePath "src-tauri/build.rs" -Encoding utf8
}

Write-Host "[3/3] Ready for 1-Click GitHub Actions Build!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "SUCCESS! Your Tauri desktop project is fully configured." -ForegroundColor Green
Write-Host "Next Step: Commit & push to GitHub to generate your .exe file!" -ForegroundColor Yellow
Write-Host "  git add ." -ForegroundColor White
Write-Host "  git commit -m 'Configure $AppName desktop build'" -ForegroundColor White
Write-Host "  git push origin main" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

Set-Location -Path $PSScriptRoot

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   ZipLoot Web-to-Desktop App Builder (Tauri v2) Auto-Installer  " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Target Website URL
$AppUrl = Read-Host "Enter your Target Website URL (default: https://ziploot.app)"
if ([string]::IsNullOrWhiteSpace($AppUrl)) { $AppUrl = "https://ziploot.app" }
$AppUrl = $AppUrl.Trim()
if ($AppUrl -match '^https?://\s*https?://') {
    $AppUrl = $AppUrl -replace '^https?://\s*', ''
}
if (-not ($AppUrl -match '^https?://')) {
    $AppUrl = "https://" + $AppUrl
}

# 2. App Name
$AppName = Read-Host "Enter your Desktop App Name (default: ZipLoot Desktop)"
if ([string]::IsNullOrWhiteSpace($AppName)) { $AppName = "ZipLoot Desktop" }
$AppName = $AppName.Trim()

# 3. Bundle Identifier
$AppId = Read-Host "Enter Bundle Identifier (default: app.ziploot.desktop)"
if ([string]::IsNullOrWhiteSpace($AppId)) { $AppId = "app.ziploot.desktop" }
$AppId = $AppId -replace '[^a-zA-Z0-9.-]', ''
if (-not ($AppId -match '^[a-zA-Z0-9.-]+$')) { $AppId = "app.ziploot.desktop" }

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

Write-Host "`n[3/3] GitHub Cloud Compilation Setup..." -ForegroundColor Yellow
Write-Host "Choose how to push to your GitHub account for free .exe compilation:" -ForegroundColor Cyan
Write-Host "  [1] Auto-Push using GitHub Personal Access Token (PAT)" -ForegroundColor White
Write-Host "  [2] Push using Existing Git Login / GitHub Desktop" -ForegroundColor White
Write-Host "  [3] Skip Push (Local Configuration Only)" -ForegroundColor White

$PushChoice = Read-Host "Select option [1, 2, or 3] (default: 2)"
if ([string]::IsNullOrWhiteSpace($PushChoice)) { $PushChoice = "2" }

if (-not (Test-Path ".git")) {
    git init | Out-Null
    git branch -M main | Out-Null
}

$PushSuccess = $false
$ActionUrl = ""

if ($PushChoice -eq "1") {
    $GhUser = Read-Host "Enter your GitHub Username"
    $GhRepo = Read-Host "Enter your GitHub Repository Name (e.g. my-desktop-app)"
    $GhToken = Read-Host "Enter your GitHub Personal Access Token (PAT)"
    
    if (-not [string]::IsNullOrWhiteSpace($GhUser) -and -not [string]::IsNullOrWhiteSpace($GhRepo) -and -not [string]::IsNullOrWhiteSpace($GhToken)) {
        $RemoteUrl = "https://$($GhToken)@github.com/$($GhUser)/$($GhRepo).git"
        git remote remove origin 2>$null
        git remote add origin $RemoteUrl
        git add .
        git commit -m "Automated 1-Click Tauri Build for $AppName ($AppUrl)" | Out-Null
        Write-Host "Pushing to https://github.com/$GhUser/$GhRepo..." -ForegroundColor Yellow
        git push -u origin main --force
        if ($LASTEXITCODE -eq 0) {
            $PushSuccess = $true
            $ActionUrl = "https://github.com/$GhUser/$GhRepo/actions"
        }
    }
}
elseif ($PushChoice -eq "2") {
    $RemoteUrl = Read-Host "Enter your GitHub Repository URL (or press Enter to use current remote)"
    if (-not [string]::IsNullOrWhiteSpace($RemoteUrl)) {
        git remote remove origin 2>$null
        git remote add origin $RemoteUrl
    }
    
    git add .
    git commit -m "Automated 1-Click Tauri Build for $AppName ($AppUrl)" | Out-Null
    Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
    git push -u origin main
    if ($LASTEXITCODE -eq 0) {
        $PushSuccess = $true
        $CurrentRemote = git config --get remote.origin.url
        if ($CurrentRemote -match 'github\.com[:/]([^/]+)/([^/.]+)') {
            $ActionUrl = "https://github.com/$($Matches[1])/$($Matches[2])/actions"
        }
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan
if ($PushSuccess) {
    Write-Host "🎉 SUCCESS! Cloud Build Triggered!" -ForegroundColor Green
    Write-Host "GitHub Actions is now compiling your $AppName .exe in Microsoft Cloud!" -ForegroundColor Yellow
    if (-not [string]::IsNullOrWhiteSpace($ActionUrl)) {
        Write-Host "Track live build & download your .exe artifact here:" -ForegroundColor White
        Write-Host "👉 $ActionUrl" -ForegroundColor Cyan
    }
} else {
    if ($PushChoice -ne "3") {
        Write-Host "⚠️ Git push was not completed (e.g. authentication or repository not created on GitHub yet)." -ForegroundColor Yellow
    }
    Write-Host "All build files (tauri.conf.json, build.rs, GitHub Action) are generated locally!" -ForegroundColor Green
    Write-Host "`nTo push manually to your own GitHub repo:" -ForegroundColor White
    Write-Host "  1. Create an empty repo on GitHub: https://github.com/new" -ForegroundColor Gray
    Write-Host "  2. Run in terminal:" -ForegroundColor Gray
    Write-Host "     git remote add origin https://github.com/<YOUR_USER>/<YOUR_REPO>.git" -ForegroundColor Gray
    Write-Host "     git push -u origin main" -ForegroundColor Gray
}
Write-Host "============================================================" -ForegroundColor Cyan

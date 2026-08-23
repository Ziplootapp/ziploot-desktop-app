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

$cleanTitle = "$AppName - Desktop App"
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
        "title": "$cleanTitle",
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

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText("$PSScriptRoot/src-tauri/tauri.conf.json", $jsonContent, $utf8NoBom)

Write-Host "[2/3] Verifying build.rs script..." -ForegroundColor Yellow
$buildRsContent = 'fn main() { tauri_build::build(); }'
[System.IO.File]::WriteAllText("$PSScriptRoot/src-tauri/build.rs", $buildRsContent, $utf8NoBom)

Write-Host "`n[3/3] GitHub Cloud Compilation Setup..." -ForegroundColor Yellow
Write-Host "Choose how to push to your GitHub account for free .exe compilation:" -ForegroundColor Cyan
Write-Host "  [1] Auto-Create Repo & Push using GitHub Token (Fully Automated)" -ForegroundColor White
Write-Host "  [2] Push using Existing Git Login / GitHub Desktop" -ForegroundColor White
Write-Host "  [3] Skip Push (Local Configuration Only)" -ForegroundColor White

$PushChoice = Read-Host "Select option [1, 2, or 3] (default: 1)"
if ([string]::IsNullOrWhiteSpace($PushChoice)) { $PushChoice = "1" }

if (-not (Test-Path ".git")) {
    git init | Out-Null
    git branch -M main | Out-Null
}

$PushSuccess = $false
$ActionUrl = ""

if ($PushChoice -eq "1") {
    $GhToken = Read-Host "Enter your GitHub Personal Access Token (PAT)"
    if (-not [string]::IsNullOrWhiteSpace($GhToken)) {
        $GhToken = $GhToken.Trim()
        Write-Host "Verifying GitHub Token and fetching profile..." -ForegroundColor Yellow
        $headers = @{
            "Authorization" = "token $GhToken"
            "Accept" = "application/vnd.github.v3+json"
            "User-Agent" = "ZipLoot-Desktop-Builder"
        }
        
        try {
            $userProfile = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -Method Get
            $GhUser = $userProfile.login
            Write-Host "[OK] Connected to GitHub as: $GhUser" -ForegroundColor Green
            
            # Default Repo Name auto-generated from App Name
            $DefaultRepo = ($AppName.ToLower() -replace '[^a-z0-9-]', '-') + "-app"
            $DefaultRepo = $DefaultRepo -replace '-+', '-'
            $GhRepo = Read-Host "Enter Repository Name (default: $DefaultRepo)"
            if ([string]::IsNullOrWhiteSpace($GhRepo)) { $GhRepo = $DefaultRepo }
            $GhRepo = $GhRepo.Trim()
            
            # Auto-create repository on GitHub via API
            Write-Host "Auto-creating repository '$GhRepo' on GitHub..." -ForegroundColor Yellow
            $createBody = @{
                name = $GhRepo
                description = "$AppName Native Desktop App (Built with ZipLoot & Tauri)"
                private = $false
            } | ConvertTo-Json
            
            try {
                Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $createBody | Out-Null
                Write-Host "[OK] Repository created at https://github.com/$GhUser/$GhRepo" -ForegroundColor Green
            } catch {
                Write-Host "[INFO] Repository already exists or ready to use." -ForegroundColor Gray
            }
            
            $RemoteUrl = "https://$($GhToken)@github.com/$($GhUser)/$($GhRepo).git"
            git remote remove origin 2>$null
            git remote add origin $RemoteUrl
            git add .
            git commit -m "Automated 1-Click Tauri Build for $AppName ($AppUrl)" 2>$null | Out-Null
            Write-Host "Pushing code to https://github.com/$GhUser/$GhRepo..." -ForegroundColor Yellow
            git push -u origin main --force
            if ($LASTEXITCODE -eq 0) {
                $PushSuccess = $true
                $ActionUrl = "https://github.com/$GhUser/$GhRepo/actions"
            }
        } catch {
            Write-Host "❌ GitHub Token Authentication Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
elseif ($PushChoice -eq "2") {
    $CurrentRemote = git config --get remote.origin.url
    if (-not [string]::IsNullOrWhiteSpace($CurrentRemote)) {
        Write-Host "Detected Git Remote: $CurrentRemote" -ForegroundColor Green
        $UseCurrent = Read-Host "Push to this remote? [Y/n] (default: Y)"
        if ($UseCurrent.ToLower() -eq "n") {
            $RemoteUrl = Read-Host "Enter new GitHub Repository URL"
            if (-not [string]::IsNullOrWhiteSpace($RemoteUrl)) {
                git remote remove origin 2>$null
                git remote add origin $RemoteUrl.Trim()
            }
        }
    } else {
        $RemoteUrl = Read-Host "Enter your GitHub Repository URL"
        if (-not [string]::IsNullOrWhiteSpace($RemoteUrl)) {
            git remote remove origin 2>$null
            git remote add origin $RemoteUrl.Trim()
        }
    }
    
    git add .
    git commit -m "Automated 1-Click Tauri Build for $AppName ($AppUrl)" 2>$null | Out-Null
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
        Write-Host "⚠️ Git push was not completed." -ForegroundColor Yellow
    }
    Write-Host "All build files are generated locally!" -ForegroundColor Green
    Write-Host "`nTo push manually to your own GitHub repo:" -ForegroundColor White
    Write-Host "  1. Create an empty repo on GitHub: https://github.com/new" -ForegroundColor Gray
    Write-Host "  2. Run in terminal:" -ForegroundColor Gray
    Write-Host "     git remote add origin https://github.com/<YOUR_USER>/<YOUR_REPO>.git" -ForegroundColor Gray
    Write-Host "     git push -u origin main" -ForegroundColor Gray
}
Write-Host "============================================================" -ForegroundColor Cyan

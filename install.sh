#!/usr/bin/env bash
cd "$(dirname "$0")"

echo "============================================================"
echo "   ZipLoot Web-to-Desktop App Builder (Tauri v2) Auto-Installer  "
echo "============================================================"

read -p "Enter Target Website URL (default: https://ziploot.app): " APP_URL
APP_URL=${APP_URL:-https://ziploot.app}

if [[ ! $APP_URL =~ ^https?:// ]]; then
  APP_URL="https://$APP_URL"
fi

read -p "Enter Desktop App Name (default: ZipLoot Desktop): " APP_NAME
APP_NAME=${APP_NAME:-ZipLoot Desktop}

read -p "Enter Bundle Identifier (default: app.ziploot.desktop): " APP_ID
APP_ID=${APP_ID:-app.ziploot.desktop}

echo -e "\n[1/2] Generating src-tauri/tauri.conf.json..."

cat <<EOF > src-tauri/tauri.conf.json
{
  "\$schema": "https://raw.githubusercontent.com/tauri-apps/tauri/dev/tooling/cli/schema.json",
  "productName": "${APP_NAME}",
  "version": "1.0.0",
  "identifier": "${APP_ID}",
  "build": {
    "frontendDist": "${APP_URL}"
  },
  "app": {
    "windows": [
      {
        "title": "${APP_NAME} — Native Desktop App",
        "url": "${APP_URL}",
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
EOF

echo "[2/2] Verifying build.rs script..."
cat <<EOF > src-tauri/build.rs
fn main() {
    tauri_build::build();
}
EOF

echo "------------------------------------------------------------"
echo "Select Build Mode:"
echo "  [1] Save Project Files Locally on PC (Offline Mode)"
echo "  [2] Auto-Push to GitHub & Trigger Cloud .exe Build"
read -p "Enter Choice [1 or 2] (default: 1): " MODE
MODE=${MODE:-1}

if [ "$MODE" = "2" ]; then
    read -p "Enter your GitHub Username: " GH_USER
    read -p "Enter your GitHub Repo Name (e.g. my-desktop-app): " GH_REPO
    read -p "Enter your GitHub PAT Token (ghp_xxxx...): " GH_PAT

    if [ ! -d ".git" ]; then
        git init -q
    fi

    if [ -n "$GH_USER" ]; then
        git config user.name "$GH_USER"
        git config user.email "$GH_USER@users.noreply.github.com"
    fi

    git add .
    git commit -m "Automated Tauri Build for ${APP_NAME} (${APP_URL})" -q

    if [ -n "$GH_USER" ] && [ -n "$GH_REPO" ] && [ -n "$GH_PAT" ]; then
        AUTH_URL="https://${GH_PAT}@github.com/${GH_USER}/${GH_REPO}.git"
        git remote remove origin > /dev/null 2>&1
        git remote add origin "$AUTH_URL"
        git branch -M main > /dev/null 2>&1
        git push -u origin main
        echo "============================================================"
        echo "🎉 SUCCESS! Cloud Build Triggered on GitHub!"
        echo "Track live build & download your .exe artifact here:"
        echo "👉 https://github.com/${GH_USER}/${GH_REPO}/actions"
        echo "============================================================"
    fi
else
    echo "============================================================"
    echo "🎉 SUCCESS! Project Files Saved Locally on your PC!"
    echo "============================================================"
fi

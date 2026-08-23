#!/usr/bin/env bash
cd "$(dirname "$0")"

echo "============================================================"
echo "   ZipLoot Web-to-Desktop App Builder (Tauri v2) Auto-Installer  "
echo "============================================================"

read -p "Enter Target Website URL (default: https://ziploot.app): " APP_URL
APP_URL=${APP_URL:-https://ziploot.app}
APP_URL=$(echo "$APP_URL" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
if [[ $APP_URL =~ ^https?://[[:space:]]*https?:// ]]; then
  APP_URL=$(echo "$APP_URL" | sed -e 's/^https\?:\/\/[[:space:]]*//')
fi
if [[ ! $APP_URL =~ ^https?:// ]]; then
  APP_URL="https://$APP_URL"
fi

read -p "Enter Desktop App Name (default: ZipLoot Desktop): " APP_NAME
APP_NAME=${APP_NAME:-ZipLoot Desktop}

read -p "Enter Bundle Identifier (default: app.ziploot.desktop): " APP_ID
APP_ID=${APP_ID:-app.ziploot.desktop}
APP_ID=$(echo "$APP_ID" | tr -cd '[:alnum:].-')
if [[ -z "$APP_ID" ]]; then
  APP_ID="app.ziploot.desktop"
fi

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

cat <<EOF > src-tauri/build.rs
fn main() {
    tauri_build::build();
}
EOF

echo ""
echo "Choose how to push to your GitHub account for free .exe compilation:"
echo "  [1] Auto-Push using GitHub Personal Access Token (PAT)"
echo "  [2] Push using Existing Git Login / GitHub Desktop"
echo "  [3] Skip Push (Local Configuration Only)"

read -p "Select option [1, 2, or 3] (default: 2): " PUSH_CHOICE
PUSH_CHOICE=${PUSH_CHOICE:-2}

if [ ! -d ".git" ]; then
    git init > /dev/null 2>&1
    git branch -M main > /dev/null 2>&1
fi

PUSH_SUCCESS=0
ACTION_URL=""

if [ "$PUSH_CHOICE" == "1" ]; then
    read -p "Enter your GitHub Username: " GH_USER
    read -p "Enter your GitHub Repository Name (e.g. my-desktop-app): " GH_REPO
    read -s -p "Enter your GitHub Personal Access Token (PAT): " GH_TOKEN
    echo ""
    
    if [ -n "$GH_USER" ] && [ -n "$GH_REPO" ] && [ -n "$GH_TOKEN" ]; then
        git remote remove origin 2>/dev/null
        git remote add origin "https://${GH_TOKEN}@github.com/${GH_USER}/${GH_REPO}.git"
        git add .
        git commit -m "Automated 1-Click Tauri Build for ${APP_NAME} (${APP_URL})" > /dev/null 2>&1
        echo "Pushing to https://github.com/${GH_USER}/${GH_REPO}..."
        git push -u origin main --force
        if [ $? -eq 0 ]; then
            PUSH_SUCCESS=1
            ACTION_URL="https://github.com/${GH_USER}/${GH_REPO}/actions"
        fi
    fi
elif [ "$PUSH_CHOICE" == "2" ]; then
    read -p "Enter your GitHub Repository URL (or press Enter to use current remote): " REMOTE_URL
    if [ -n "$REMOTE_URL" ]; then
        git remote remove origin 2>/dev/null
        git remote add origin "$REMOTE_URL"
    fi
    git add .
    git commit -m "Automated 1-Click Tauri Build for ${APP_NAME} (${APP_URL})" > /dev/null 2>&1
    echo "Pushing to GitHub..."
    git push -u origin main
    if [ $? -eq 0 ]; then
        PUSH_SUCCESS=1
        CURRENT_REMOTE=$(git config --get remote.origin.url)
        if [[ $CURRENT_REMOTE =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
            ACTION_URL="https://github.com/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/actions"
        fi
    fi
fi

echo "============================================================"
if [ $PUSH_SUCCESS -eq 1 ]; then
    echo "🎉 SUCCESS! Cloud Build Triggered!"
    echo "GitHub Actions is now compiling your ${APP_NAME} .exe in Microsoft Cloud!"
    if [ -n "$ACTION_URL" ]; then
        echo "Track live build & download your .exe artifact here:"
        echo "👉 $ACTION_URL"
    fi
else
    if [ "$PUSH_CHOICE" != "3" ]; then
        echo "⚠️ Git push was not completed (e.g. authentication or repository not created on GitHub yet)."
    fi
    echo "All build files are generated locally!"
    echo ""
    echo "To push manually to your own GitHub repo:"
    echo "  1. Create an empty repo on GitHub: https://github.com/new"
    echo "  2. Run:"
    echo "     git remote add origin https://github.com/<YOUR_USER>/<YOUR_REPO>.git"
    echo "     git push -u origin main"
fi
echo "============================================================"

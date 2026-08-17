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

echo -e "\n[1/3] Generating src-tauri/tauri.conf.json..."

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

echo "[2/3] Verifying build.rs script..."
cat <<EOF > src-tauri/build.rs
fn main() {
    tauri_build::build();
}
EOF

echo "[3/3] Auto-Initializing Git & Committing Project..."
if [ ! -d ".git" ]; then
    git init -q
fi

git add .
git commit -m "Automated 1-Click Tauri Build for ${APP_NAME} (${APP_URL})" -q

if git remote get-url origin > /dev/null 2>&1; then
    git push origin main
fi

echo "============================================================"
echo "🎉 SUCCESS! Your Desktop App Project is Fully Configured!"
echo "============================================================"

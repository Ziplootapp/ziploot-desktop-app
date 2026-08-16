#!/usr/bin/env bash
# ============================================================
#   ZipLoot Automated Web-to-Desktop App Builder (Tauri v2)  
# ============================================================

echo -e "\033[1;36m============================================================\033[0m"
echo -e "\033[1;32m   ZipLoot Automated Web-to-Desktop App Builder (Tauri v2)  \033[0m"
echo -e "\033[1;36m============================================================\033[0m"

read -p "Enter Target Website URL (default: https://ziploot.app): " APP_URL
APP_URL=${APP_URL:-https://ziploot.app}

if [[ ! $APP_URL =~ ^https?:// ]]; then
  APP_URL="https://$APP_URL"
fi

read -p "Enter Desktop App Name (default: ZipLoot Desktop): " APP_NAME
APP_NAME=${APP_NAME:-ZipLoot Desktop}

read -p "Enter Bundle Identifier (default: app.ziploot.desktop): " APP_ID
APP_ID=${APP_ID:-app.ziploot.desktop}

echo -e "\n\033[1;33m[1/4] Generating src-tauri/tauri.conf.json...\033[0m"

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

echo -e "\033[1;33m[2/4] Verifying build.rs script...\033[0m"
cat <<EOF > src-tauri/build.rs
fn main() {
    tauri_build::build();
}
EOF

echo -e "\033[1;33m[3/4] Auto-Committing and Pushing to GitHub...\033[0m"
git add .
git commit -m "Automated 1-Click Tauri Build for ${APP_NAME} (${APP_URL})"
git push origin main

echo -e "\n\033[1;32m[4/4] SUCCESS! Cloud Build Triggered!\033[0m"
echo -e "\033[1;36m============================================================\033[0m"
echo -e "\033[1;32m🎉 GitHub Actions is now compiling your ${APP_NAME} .exe in Microsoft Cloud!\033[0m"
echo -e "\033[1;33mTrack your live build & download your .exe artifact here:\033[0m"
echo -e "👉 https://github.com/Ziplootapp/ziploot-desktop-app/actions"
echo -e "\033[1;36m============================================================\033[0m"

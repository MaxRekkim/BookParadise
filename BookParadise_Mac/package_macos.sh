#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "=== 1. Сборка React/Tailwind интерфейса (Vite) ==="
export PATH="/Users/max/.gemini/antigravity/scratch/tools/node-v20.18.0-darwin-arm64/bin:$PATH"
npm run build

echo "=== 2. Создание структуры BookParadise.app ==="
APP_NAME="BookParadise"
APP_BUNDLE="${DIR}/${APP_NAME}.app"
rm -rf "$APP_BUNDLE"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

echo "=== 3. Компиляция нативного Cocoa/WebKit раннера ==="
clang -O2 -fobjc-arc \
  -target arm64-apple-macos12.0 \
  -framework Cocoa \
  -framework WebKit \
  "${DIR}/macos-runner/main.m" \
  -o "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

echo "=== 4. Копирование ресурсов и манифеста Info.plist ==="
cp "${DIR}/macos-runner/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
cp -r "${DIR}/dist" "${APP_BUNDLE}/Contents/Resources/"

echo "=== 5. Создание инсталлятора PKG ==="
VERSION="2.12.0"
PKG_NAME="BookParadise-${VERSION}.pkg"
rm -rf pkg_root "$PKG_NAME"
mkdir -p pkg_root
cp -r "${APP_BUNDLE}" pkg_root/
pkgbuild --root pkg_root --identifier com.maxim.bookparadise.mac --version "$VERSION" --install-location /Applications "${DIR}/${PKG_NAME}"
rm -rf pkg_root

echo "=== 6. Создание образа диска DMG ==="
DMG_NAME="BookParadise-${VERSION}.dmg"
DMG_STAGING="${DIR}/dmg_staging"
rm -rf "$DMG_STAGING" "$DMG_NAME"
mkdir -p "$DMG_STAGING"
cp -r "${APP_BUNDLE}" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create -volname "BookParadise" -srcfolder "$DMG_STAGING" -ov -format UDZO "${DIR}/${DMG_NAME}"
rm -rf "$DMG_STAGING"

echo "======================================================"
echo "✅ СБОРКА УСПЕШНО ЗАВЕРШЕНА!"
echo "   Приложение:  ${APP_BUNDLE}"
echo "   Инсталлятор: ${DIR}/${PKG_NAME}"
echo "   Образ диска: ${DIR}/${DMG_NAME}"
echo "======================================================"

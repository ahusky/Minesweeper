#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "🔨 编译扫雷游戏..."

swiftc -parse-as-library \
    -framework SwiftUI \
    -framework AppKit \
    -O \
    -o MinesweeperBinary \
    Sources/Models/GameModel.swift \
    Sources/Models/GameStatistics.swift \
    Sources/Models/LeaderboardManager.swift \
    Sources/Views/HeaderView.swift \
    Sources/Views/GameBoardView.swift \
    Sources/Views/StatsCenter.swift \
    Sources/Views/AppColors.swift \
    Sources/Views/HelpView.swift \
    Sources/App/MinesweeperApp.swift

# 创建 .app bundle
APP_DIR="build/扫雷Lite.app"
rm -rf build
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mv MinesweeperBinary "$APP_DIR/Contents/MacOS/Minesweeper"

# 生成图标
LOGO="Resources/logo.png"
if [ -f "$LOGO" ]; then
    echo "🎨 生成应用图标..."
    ICONSET_DIR=$(mktemp -d)
    sips -z 16 16 "$LOGO" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null 2>&1
    sips -z 32 32 "$LOGO" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null 2>&1
    sips -z 32 32 "$LOGO" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null 2>&1
    sips -z 64 64 "$LOGO" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null 2>&1
    sips -z 128 128 "$LOGO" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null 2>&1
    sips -z 256 256 "$LOGO" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null 2>&1
    sips -z 256 256 "$LOGO" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null 2>&1
    sips -z 512 512 "$LOGO" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null 2>&1
    sips -z 512 512 "$LOGO" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null 2>&1
    sips -z 512 512 "$LOGO" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null 2>&1
    mv "$ICONSET_DIR" "${ICONSET_DIR}.iconset"
    iconutil -c icns "${ICONSET_DIR}.iconset" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
    rm -rf "${ICONSET_DIR}.iconset"
fi

# 创建 Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Minesweeper</string>
    <key>CFBundleIdentifier</key>
    <string>com.yuyang.Minesweeper</string>
    <key>CFBundleName</key>
    <string>扫雷Lite</string>
    <key>CFBundleDisplayName</key>
    <string>扫雷Lite</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

echo "✅ 编译完成！"
echo "📦 应用位置: $PROJECT_DIR/$APP_DIR"
echo ""
echo "运行: open $APP_DIR"
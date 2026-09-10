#!/bin/bash
# Builds Clipd.app from source with a CLT-only toolchain (no Xcode required).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/Scripts/swiftpm-env.sh"
cd "$ROOT"

# 1. Release build — universal if possible, arm64-only fallback.
if swift build -c release --arch arm64 --arch x86_64; then
  BIN=.build/apple/Products/Release/Clipd
else
  echo "warning: universal build failed; falling back to arm64 only"
  swift build -c release
  BIN=.build/release/Clipd
fi

# 2. Assemble the bundle.
APP=Clipd.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Clipd"
if [ -f Assets/AppIcon.icns ]; then
  cp Assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
else
  echo "warning: Assets/AppIcon.icns missing — run 'swift Scripts/make-icon.swift' first"
fi

# 3. Info.plist. No LSUIElement — the Dock icon is toggled at runtime.
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>Clipd</string>
	<key>CFBundleDisplayName</key>
	<string>Clipd</string>
	<key>CFBundleIdentifier</key>
	<string>com.folade.clipd</string>
	<key>CFBundleExecutable</key>
	<string>Clipd</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.productivity</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST

# 4. Ad-hoc codesign — gives the app a stable identity across rebuilds.
# Strip xattrs first: codesign refuses to seal a bundle carrying Finder info or
# resource forks ("detritus not allowed").
xattr -cr "$APP"
codesign --force --sign - "$APP"

# 5. Zip for distribution. Must be ditto, not zip: plain zip stores xattrs as
# AppleDouble (._Clipd) files that land inside the bundle on extraction and
# break the signature seal for whoever downloads it.
ditto -c -k --sequesterRsrc --keepParent "$APP" "$APP.zip"

# 6. Verify the extracted copy — that's what a downloader actually runs. Don't
# verify "$APP" in place: if this folder syncs to iCloud Drive, the .app gets
# re-stamped with com.apple.FinderInfo within seconds of signing, so an on-disk
# check fails even when the archived copy is perfectly fine.
VERIFY_DIR="$(mktemp -d)"
ditto -x -k "$APP.zip" "$VERIFY_DIR"
codesign --verify --deep --strict "$VERIFY_DIR/$APP"
rm -rf "$VERIFY_DIR"

echo "Built $ROOT/$APP"
echo "Packaged $ROOT/$APP.zip (signature verified from the archive)"

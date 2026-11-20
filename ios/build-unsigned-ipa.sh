#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$SCRIPT_DIR/Xuanshu.xcodeproj"
BUILD_DIR="$SCRIPT_DIR/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
IPA_PATH="$BUILD_DIR/Xuanshu-unsigned.ipa"

command -v xcodebuild >/dev/null 2>&1 || {
  echo "需要在安装 Xcode 的 macOS 上运行此脚本。" >&2
  exit 1
}

rm -rf "$DERIVED_DATA" "$BUILD_DIR/Payload" "$IPA_PATH"
mkdir -p "$BUILD_DIR/Payload"

xcodebuild \
  -project "$PROJECT" \
  -scheme Xuanshu \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  clean build

APP_PATH="$(find "$DERIVED_DATA/Build/Products/Release-iphoneos" -maxdepth 1 -name 'Xuanshu.app' -print -quit)"
if [[ -z "$APP_PATH" ]]; then
  echo "未找到构建产物 Xuanshu.app" >&2
  exit 1
fi

cp -R "$APP_PATH" "$BUILD_DIR/Payload/"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$BUILD_DIR/Payload" "$IPA_PATH"

echo "未签名 IPA 已生成：$IPA_PATH"

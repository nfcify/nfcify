#!/bin/bash

# NFCify 빌드 준비 가이드
# 이 스크립트는 nfcify-source에서 빌드한 파일들을 nfcify 배포 저장소로 복사하는 가이드입니다.

set -e

# 버전 결정: 명령행 인자 또는 version.py에서 읽기
if [ -n "$1" ]; then
    VERSION=$1
    echo "📌 명령행에서 지정한 버전 사용: $VERSION"
else
    # version.py에서 버전 읽기
    if [ -f "version.py" ]; then
        VERSION=$(python3 -c "import sys; sys.path.insert(0, '.'); from version import __version__; print(__version__)")
        echo "📌 version.py에서 버전 읽기: $VERSION"
    else
        echo "❌ version.py 파일을 찾을 수 없습니다."
        echo "사용법: $0 [version]"
        echo "예시: $0 0.1.0"
        echo ""
        echo "또는 nfcify 저장소 루트에 version.py 파일을 생성하세요."
        exit 1
    fi
fi

echo "=================================================="
echo "📦 NFCify v$VERSION 빌드 파일 준비"
echo "=================================================="
echo ""
echo "이 스크립트는 nfcify-source에서 빌드한 파일들을 배포 저장소로 복사합니다."
echo ""
echo "필요한 빌드 파일:"
echo "  1. macOS (Apple Silicon): NFCify-${VERSION}-macos-arm64.dmg"
echo "  2. macOS (Intel): NFCify-${VERSION}-macos-x86_64.dmg"
echo "  3. Windows: NFCify-${VERSION}-windows.exe"
echo ""
echo "=================================================="
echo "빌드 방법:"
echo "=================================================="
echo ""
echo "1. macOS (Apple Silicon) 빌드:"
echo "   - Apple Silicon Mac에서 실행"
echo "   cd /path/to/nfcify-source"
echo "   ./script/distribute_macos.sh"
echo "   # 생성된 NFCify-0.1.0.dmg를 NFCify-${VERSION}-macos-arm64.dmg로 이름 변경"
echo ""
echo "2. macOS (Intel) 빌드:"
echo "   - Intel Mac에서 실행"
echo "   cd /path/to/nfcify-source"
echo "   ./script/distribute_macos.sh"
echo "   # 생성된 NFCify-0.1.0.dmg를 NFCify-${VERSION}-macos-x86_64.dmg로 이름 변경"
echo ""
echo "3. Windows 빌드:"
echo "   - Windows PC에서 실행"
echo "   cd C:\\path\\to\\nfcify-source"
echo "   .\\script\\bundle_windows.bat"
echo "   # 생성된 dist\\NFCify.exe를 NFCify-${VERSION}-windows.exe로 이름 변경"
echo ""
echo "=================================================="
echo "파일 복사 방법:"
echo "=================================================="
echo ""

# nfcify-source 경로 확인
NFCIFY_SOURCE_PATH="${NFCIFY_SOURCE_PATH:-../nfcify-source}"

if [ ! -d "$NFCIFY_SOURCE_PATH" ]; then
    echo "⚠️  nfcify-source 경로를 찾을 수 없습니다: $NFCIFY_SOURCE_PATH"
    echo ""
    echo "환경변수 NFCIFY_SOURCE_PATH를 설정하거나,"
    echo "nfcify-source가 ../nfcify-source에 있는지 확인하세요."
    echo ""
    read -p "수동으로 파일을 복사하시겠습니까? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    
    echo ""
    echo "다음 위치에 빌드 파일을 복사하세요:"
    echo "  dist/NFCify-${VERSION}-macos-arm64.dmg"
    echo "  dist/NFCify-${VERSION}-macos-x86_64.dmg"
    echo "  dist/NFCify-${VERSION}-windows.exe"
    echo ""
    exit 0
fi

echo "nfcify-source 경로: $NFCIFY_SOURCE_PATH"
echo ""

# dist 디렉토리 생성
mkdir -p dist

# 파일 복사 시도
COPIED_FILES=0

# macOS arm64 DMG
if [ -f "dist/NFCify-${VERSION}-macos-arm64.dmg" ]; then
    echo "✅ macOS (Apple Silicon) DMG가 이미 준비되어 있습니다: dist/NFCify-${VERSION}-macos-arm64.dmg"
    COPIED_FILES=$((COPIED_FILES + 1))
elif [ -f "$NFCIFY_SOURCE_PATH/NFCify-${VERSION}-macos-arm64.dmg" ]; then
    echo "📦 macOS (Apple Silicon) DMG 복사 중..."
    cp "$NFCIFY_SOURCE_PATH/NFCify-${VERSION}-macos-arm64.dmg" dist/
    echo "✅ 복사 완료: dist/NFCify-${VERSION}-macos-arm64.dmg"
    COPIED_FILES=$((COPIED_FILES + 1))
elif [ -f "$NFCIFY_SOURCE_PATH/NFCify-0.1.0.dmg" ]; then
    echo "📦 macOS DMG 발견 (버전 이름 변경 필요)"
    read -p "NFCify-0.1.0.dmg를 NFCify-${VERSION}-macos-arm64.dmg로 복사하시겠습니까? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$NFCIFY_SOURCE_PATH/NFCify-0.1.0.dmg" "dist/NFCify-${VERSION}-macos-arm64.dmg"
        echo "✅ 복사 완료: dist/NFCify-${VERSION}-macos-arm64.dmg"
        COPIED_FILES=$((COPIED_FILES + 1))
    fi
else
    echo "⚠️  macOS (Apple Silicon) DMG를 찾을 수 없습니다."
fi

# macOS arm64 ZIP
if [ -f "dist/NFCify-${VERSION}-macos-arm64.zip" ]; then
    echo "✅ macOS (Apple Silicon) ZIP가 이미 준비되어 있습니다: dist/NFCify-${VERSION}-macos-arm64.zip"
    COPIED_FILES=$((COPIED_FILES + 1))
elif [ -f "$NFCIFY_SOURCE_PATH/NFCify-${VERSION}-macos-arm64.zip" ]; then
    echo "📦 macOS (Apple Silicon) ZIP 복사 중..."
    cp "$NFCIFY_SOURCE_PATH/NFCify-${VERSION}-macos-arm64.zip" dist/
    echo "✅ 복사 완료: dist/NFCify-${VERSION}-macos-arm64.zip"
    COPIED_FILES=$((COPIED_FILES + 1))
else
    echo "⚠️  macOS (Apple Silicon) ZIP를 찾을 수 없습니다."
fi

echo ""

# macOS x86_64 DMG
if [ -f "dist/NFCify-${VERSION}-macos-x86_64.dmg" ]; then
    echo "✅ macOS (Intel) DMG가 이미 준비되어 있습니다: dist/NFCify-${VERSION}-macos-x86_64.dmg"
    COPIED_FILES=$((COPIED_FILES + 1))
elif [ -f "$NFCIFY_SOURCE_PATH/NFCify-${VERSION}-macos-x86_64.dmg" ]; then
    echo "📦 macOS (Intel) DMG 복사 중..."
    cp "$NFCIFY_SOURCE_PATH/NFCify-${VERSION}-macos-x86_64.dmg" dist/
    echo "✅ 복사 완료: dist/NFCify-${VERSION}-macos-x86_64.dmg"
    COPIED_FILES=$((COPIED_FILES + 1))
else
    echo "⚠️  macOS (Intel) DMG를 찾을 수 없습니다."
fi

# macOS x86_64 ZIP
if [ -f "dist/NFCify-${VERSION}-macos-x86_64.zip" ]; then
    echo "✅ macOS (Intel) ZIP가 이미 준비되어 있습니다: dist/NFCify-${VERSION}-macos-x86_64.zip"
    COPIED_FILES=$((COPIED_FILES + 1))
elif [ -f "$NFCIFY_SOURCE_PATH/NFCify-${VERSION}-macos-x86_64.zip" ]; then
    echo "📦 macOS (Intel) ZIP 복사 중..."
    cp "$NFCIFY_SOURCE_PATH/NFCify-${VERSION}-macos-x86_64.zip" dist/
    echo "✅ 복사 완료: dist/NFCify-${VERSION}-macos-x86_64.zip"
    COPIED_FILES=$((COPIED_FILES + 1))
else
    echo "⚠️  macOS (Intel) ZIP를 찾을 수 없습니다."
fi

echo ""

# Windows
if [ -f "dist/NFCify-${VERSION}-windows.exe" ]; then
    echo "✅ Windows EXE가 이미 준비되어 있습니다: dist/NFCify-${VERSION}-windows.exe"
    COPIED_FILES=$((COPIED_FILES + 1))
elif [ -f "$NFCIFY_SOURCE_PATH/NFCify-${VERSION}-windows.exe" ]; then
    echo "📦 Windows EXE 복사 중..."
    cp "$NFCIFY_SOURCE_PATH/NFCify-${VERSION}-windows.exe" dist/
    echo "✅ 복사 완료: dist/NFCify-${VERSION}-windows.exe"
    COPIED_FILES=$((COPIED_FILES + 1))
elif [ -f "$NFCIFY_SOURCE_PATH/dist/NFCify.exe" ]; then
    echo "📦 Windows EXE 발견 (버전 이름 변경 필요)"
    read -p "dist/NFCify.exe를 NFCify-${VERSION}-windows.exe로 복사하시겠습니까? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$NFCIFY_SOURCE_PATH/dist/NFCify.exe" "dist/NFCify-${VERSION}-windows.exe"
        echo "✅ 복사 완료: dist/NFCify-${VERSION}-windows.exe"
        COPIED_FILES=$((COPIED_FILES + 1))
    fi
else
    echo "⚠️  Windows EXE를 찾을 수 없습니다."
fi

echo ""
echo "=================================================="
echo "📊 복사 결과"
echo "=================================================="
echo "복사된 파일: $COPIED_FILES / 3"
echo ""

if [ $COPIED_FILES -eq 3 ]; then
    echo "✅ 모든 빌드 파일이 준비되었습니다!"
    echo ""
    echo "다음 단계:"
    echo "  ./scripts/release.sh $VERSION"
elif [ $COPIED_FILES -gt 0 ]; then
    echo "⚠️  일부 빌드 파일만 준비되었습니다."
    echo ""
    echo "누락된 플랫폼의 빌드를 완료한 후 다시 실행하거나,"
    echo "release.sh 실행 시 누락된 파일을 건너뛸 수 있습니다."
else
    echo "❌ 빌드 파일을 찾을 수 없습니다."
    echo ""
    echo "nfcify-source에서 먼저 빌드를 완료해주세요."
fi

echo ""

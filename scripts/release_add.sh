#!/bin/bash

# GitHub Release 파일 추가 스크립트
# 사용법: ./scripts/release_add.sh [version]
# 버전을 생략하면 version.py에서 자동으로 읽어옵니다.
#
# 이 스크립트는 이미 생성된 GitHub Release에 빌드 파일을 추가 업로드합니다.
# 같은 이름의 파일이 이미 있으면 자동으로 삭제 후 재업로드합니다.

set -e  # 에러 발생 시 스크립트 중단

# ================================================
# 프로젝트 설정
# ================================================
PROJECT_NAME="NFCify"
GITHUB_REPO="nfcify/nfcify"

# GitHub Personal Access Token (환경변수에서 읽기)
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
# ================================================

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
        exit 1
    fi
fi

TAG="v$VERSION"

echo "=================================================="
echo "📤 릴리즈 $TAG에 파일 추가"
echo "=================================================="

# 1. GitHub Token 확인
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN 환경변수가 설정되지 않았습니다."
    echo "💡 설정 방법:"
    echo "   1. https://github.com/settings/tokens 에서 토큰 생성 (repo 권한 필요)"
    echo "   2. export GITHUB_TOKEN=\"your_token_here\" 실행"
    echo "   또는 ~/.bashrc, ~/.zshrc에 추가"
    exit 1
fi

# 2. 릴리즈 존재 확인
echo ""
echo "🔍 릴리즈 확인 중..."

RELEASE_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_REPO/releases/tags/$TAG")

RELEASE_ID=$(echo "$RELEASE_RESPONSE" | jq -r .id)

if [ "$RELEASE_ID" = "null" ] || [ -z "$RELEASE_ID" ]; then
    echo "❌ 릴리즈 $TAG를 찾을 수 없습니다."
    echo "💡 먼저 릴리즈를 생성하세요: ./scripts/release.sh $VERSION"
    exit 1
fi

echo "✅ 릴리즈 발견 (ID: $RELEASE_ID)"

# 3. 빌드 파일 확인
echo ""
echo "📦 빌드 파일 확인 중..."

# 배포 파일 경로 설정
DMG_ARM64_PATH="dist/${PROJECT_NAME}-${VERSION}-macos-arm64.dmg"
ZIP_ARM64_PATH="dist/${PROJECT_NAME}-${VERSION}-macos-arm64.zip"
DMG_X86_64_PATH="dist/${PROJECT_NAME}-${VERSION}-macos-x86_64.dmg"
ZIP_X86_64_PATH="dist/${PROJECT_NAME}-${VERSION}-macos-x86_64.zip"
WINDOWS_EXE_PATH="dist/${PROJECT_NAME}-${VERSION}-windows.exe"

FOUND_FILES=()

if [ -f "$DMG_ARM64_PATH" ]; then
    FOUND_FILES+=("$DMG_ARM64_PATH")
else
    echo "⚠️  $DMG_ARM64_PATH 파일을 찾을 수 없습니다."
fi

if [ -f "$ZIP_ARM64_PATH" ]; then
    FOUND_FILES+=("$ZIP_ARM64_PATH")
else
    echo "⚠️  $ZIP_ARM64_PATH 파일을 찾을 수 없습니다."
fi

if [ -f "$DMG_X86_64_PATH" ]; then
    FOUND_FILES+=("$DMG_X86_64_PATH")
else
    echo "⚠️  $DMG_X86_64_PATH 파일을 찾을 수 없습니다."
fi

if [ -f "$ZIP_X86_64_PATH" ]; then
    FOUND_FILES+=("$ZIP_X86_64_PATH")
else
    echo "⚠️  $ZIP_X86_64_PATH 파일을 찾을 수 없습니다."
fi

if [ -f "$WINDOWS_EXE_PATH" ]; then
    FOUND_FILES+=("$WINDOWS_EXE_PATH")
else
    echo "⚠️  $WINDOWS_EXE_PATH 파일을 찾을 수 없습니다."
fi

if [ ${#FOUND_FILES[@]} -eq 0 ]; then
    echo ""
    echo "❌ 업로드할 빌드 파일을 찾을 수 없습니다."
    echo ""
    echo "💡 빌드 파일을 먼저 dist 폴더에 준비해주세요."
    exit 1
fi

echo "✅ ${#FOUND_FILES[@]}개의 빌드 파일 발견"
for file in "${FOUND_FILES[@]}"; do
    echo "  ✅ $file"
done
echo ""

# 4. 확인
read -p "이 파일들을 릴리즈 $TAG에 업로드하시겠습니까? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 업로드가 취소되었습니다."
    exit 1
fi

# 5. 파일 업로드
echo ""
echo "📤 빌드 파일 업로드 중..."

UPLOAD_URL="https://uploads.github.com/repos/$GITHUB_REPO/releases/$RELEASE_ID/assets"

for file_path in "${FOUND_FILES[@]}"; do
    filename=$(basename "$file_path")

    # 파일이 이미 업로드되었는지 확인
    ASSETS_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$GITHUB_REPO/releases/$RELEASE_ID/assets")

    ASSET_ID=$(echo "$ASSETS_RESPONSE" | jq -r ".[] | select(.name == \"$filename\") | .id")

    if [ -n "$ASSET_ID" ] && [ "$ASSET_ID" != "null" ]; then
        echo "⚠️  $filename 파일이 이미 존재합니다. 삭제 후 재업로드합니다..."
        curl -s -X DELETE \
          -H "Authorization: token $GITHUB_TOKEN" \
          -H "Accept: application/vnd.github.v3+json" \
          "https://api.github.com/repos/$GITHUB_REPO/releases/assets/$ASSET_ID" > /dev/null
    fi

    echo "📤 $filename 업로드 중..."

    # Content-Type 결정
    if [[ "$filename" == *.dmg ]]; then
        CONTENT_TYPE="application/octet-stream"
    elif [[ "$filename" == *.zip ]]; then
        CONTENT_TYPE="application/zip"
    elif [[ "$filename" == *.exe ]]; then
        CONTENT_TYPE="application/octet-stream"
    else
        CONTENT_TYPE="application/octet-stream"
    fi

    UPLOAD_RESPONSE=$(curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: $CONTENT_TYPE" \
      --data-binary "@$file_path" \
      "$UPLOAD_URL?name=$filename")

    # 업로드 결과 확인
    UPLOAD_STATE=$(echo "$UPLOAD_RESPONSE" | jq -r .state)
    if [ "$UPLOAD_STATE" = "uploaded" ]; then
        echo "✅ $filename 업로드 완료"
    else
        echo "❌ $filename 업로드 실패"
        echo "$UPLOAD_RESPONSE" | jq .
        exit 1
    fi
done

echo ""
echo "=================================================="
echo "✅ 파일 추가 완료!"
echo "=================================================="
echo ""
echo "🔗 릴리즈 페이지: https://github.com/$GITHUB_REPO/releases/tag/$TAG"
echo ""

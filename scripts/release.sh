#!/bin/bash

# GitHub Release Script for NFCify
# 사용법: ./scripts/release.sh [version]
# 버전을 생략하면 version.py에서 자동으로 읽어옵니다.
# 
# 이 스크립트는 다음 3개의 플랫폼 빌드를 배포합니다:
# - macOS (Apple Silicon - arm64)
# - macOS (Intel - x86_64)
# - Windows (x86_64)

set -e  # 에러 발생 시 스크립트 중단

# ================================================
# 프로젝트 설정
# ================================================
PROJECT_NAME="NFCify"
GITHUB_REPO="nfcify/nfcify"

# GitHub Personal Access Token (환경변수에서 읽기)
# export GITHUB_TOKEN="your_token_here" 또는 ~/.bashrc, ~/.zshrc에 추가
# 토큰 생성: https://github.com/settings/tokens (repo 권한 필요)
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
        echo ""
        echo "또는 nfcify 저장소 루트에 version.py 파일을 생성하세요."
        exit 1
    fi
fi

TAG="v$VERSION"

# 배포 파일 경로 설정
DMG_ARM64_PATH="dist/${PROJECT_NAME}-${VERSION}-macos-arm64.dmg"
ZIP_ARM64_PATH="dist/${PROJECT_NAME}-${VERSION}-macos-arm64.zip"
DMG_X86_64_PATH="dist/${PROJECT_NAME}-${VERSION}-macos-x86_64.dmg"
ZIP_X86_64_PATH="dist/${PROJECT_NAME}-${VERSION}-macos-x86_64.zip"
WINDOWS_EXE_PATH="dist/${PROJECT_NAME}-${VERSION}-windows.exe"

echo "=================================================="
echo "🚀 $PROJECT_NAME v$VERSION 배포를 시작합니다"
echo "=================================================="

# 1. 현재 브랜치 확인
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 현재 브랜치: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "main" ]; then
    read -p "⚠️  main 브랜치가 아닙니다. 계속하시겠습니까? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 2. 변경사항 확인
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ 커밋되지 않은 변경사항이 있습니다."
    git status --short
    exit 1
fi

# 3. 태그 중복 확인
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "❌ 태그 $TAG가 이미 존재합니다."
    exit 1
fi

# 4. 빌드 파일 경로 확인
echo ""
echo "📦 빌드 파일 확인 중..."

MISSING_FILES=()

if [ ! -f "$DMG_ARM64_PATH" ]; then
    echo "⚠️  $DMG_ARM64_PATH 파일을 찾을 수 없습니다."
    MISSING_FILES+=("macOS (Apple Silicon)")
fi

if [ ! -f "$DMG_X86_64_PATH" ]; then
    echo "⚠️  $DMG_X86_64_PATH 파일을 찾을 수 없습니다."
    MISSING_FILES+=("macOS (Intel)")
fi

if [ ! -f "$WINDOWS_EXE_PATH" ]; then
    echo "⚠️  $WINDOWS_EXE_PATH 파일을 찾을 수 없습니다."
    MISSING_FILES+=("Windows")
fi

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo ""
    echo "❌ 다음 플랫폼의 빌드 파일이 없습니다:"
    for platform in "${MISSING_FILES[@]}"; do
        echo "   - $platform"
    done
    echo ""
    echo "💡 빌드 파일을 먼저 생성해주세요:"
    echo "   - macOS (Apple Silicon): nfcify-source에서 Apple Silicon Mac에서 빌드"
    echo "   - macOS (Intel): nfcify-source에서 Intel Mac에서 빌드"
    echo "   - Windows: nfcify-source에서 Windows에서 빌드"
    echo ""
    read -p "누락된 파일이 있어도 계속하시겠습니까? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✅ 빌드 파일 확인 완료"
echo ""


# 5. GitHub Token 확인
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN 환경변수가 설정되지 않았습니다."
    echo "💡 설정 방법:"
    echo "   1. https://github.com/settings/tokens 에서 토큰 생성 (repo 권한 필요)"
    echo "   2. export GITHUB_TOKEN=\"your_token_here\" 실행"
    echo "   또는 ~/.bashrc, ~/.zshrc에 추가"
    exit 1
fi

echo "✅ 빌드 파일 확인 완료"
echo ""

# 7. 릴리즈 노트 입력
RELEASE_NOTES_FILE=$(mktemp)
cat > "$RELEASE_NOTES_FILE" << EOF
## What's New
-

## Bug Fixes
-

## Known Issues
-
EOF

echo "📝 릴리즈 노트를 작성해주세요 (저장 후 종료하세요)..."
sleep 2
${EDITOR:-vim} "$RELEASE_NOTES_FILE"

# 8. 확인
echo ""
echo "=================================================="
echo "📋 배포 정보 확인"
echo "=================================================="
echo "버전: $VERSION"
echo "태그: $TAG"
echo ""
echo "배포 파일:"
if [ -f "$DMG_ARM64_PATH" ]; then
    echo "  ✅ macOS (Apple Silicon): $DMG_ARM64_PATH"
else
    echo "  ❌ macOS (Apple Silicon): 파일 없음"
fi
if [ -f "$DMG_X86_64_PATH" ]; then
    echo "  ✅ macOS (Intel): $DMG_X86_64_PATH"
else
    echo "  ❌ macOS (Intel): 파일 없음"
fi
if [ -f "$WINDOWS_EXE_PATH" ]; then
    echo "  ✅ Windows: $WINDOWS_EXE_PATH"
else
    echo "  ❌ Windows: 파일 없음"
fi
echo ""
echo "릴리즈 노트:"
echo "--------------------------------------------------"
cat "$RELEASE_NOTES_FILE"
echo "--------------------------------------------------"
echo ""

read -p "이대로 배포하시겠습니까? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    rm "$RELEASE_NOTES_FILE"
    echo "❌ 배포가 취소되었습니다."
    exit 1
fi

# 9. Git 태그 생성 및 푸시
echo ""
echo "🏷️  Git 태그 생성 중..."
git tag -a "$TAG" -m "Release $TAG"
git push origin "$TAG"
echo "✅ 태그 푸시 완료"

# 10. GitHub Release 생성
echo ""
echo "📤 GitHub Release 생성 중..."

# 릴리즈 노트를 JSON 포맷으로 변환 (이스케이프 처리)
# 제어 문자를 안전하게 제거하고 JSON 변환
RELEASE_BODY=$(cat "$RELEASE_NOTES_FILE" | tr -d '\000-\037' | jq -Rs .)

# GitHub API로 릴리즈 생성
RELEASE_RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$GITHUB_REPO/releases" \
  -d "{
    \"tag_name\": \"$TAG\",
    \"name\": \"$PROJECT_NAME $TAG\",
    \"body\": $RELEASE_BODY,
    \"draft\": false,
    \"prerelease\": false
  }")

# 릴리즈 ID 추출
RELEASE_ID=$(echo "$RELEASE_RESPONSE" | jq -r .id)

if [ "$RELEASE_ID" = "null" ] || [ -z "$RELEASE_ID" ]; then
    echo "❌ 릴리즈 생성 실패"
    echo "$RELEASE_RESPONSE" | jq .
    rm "$RELEASE_NOTES_FILE"
    exit 1
fi

echo "✅ 릴리즈 생성 완료 (ID: $RELEASE_ID)"

# 11. 파일 업로드
echo ""
echo "📤 빌드 파일 업로드 중..."

UPLOAD_URL="https://uploads.github.com/repos/$GITHUB_REPO/releases/$RELEASE_ID/assets"

# macOS (Apple Silicon) DMG 업로드
if [ -f "$DMG_ARM64_PATH" ]; then
    echo "📤 macOS (Apple Silicon) DMG 업로드 중..."
    DMG_ARM64_FILENAME=$(basename "$DMG_ARM64_PATH")
    
    curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/octet-stream" \
      --data-binary "@$DMG_ARM64_PATH" \
      "$UPLOAD_URL?name=$DMG_ARM64_FILENAME" > /dev/null
    
    echo "✅ macOS (Apple Silicon) DMG 업로드 완료"
fi

# macOS (Apple Silicon) ZIP 업로드
if [ -f "$ZIP_ARM64_PATH" ]; then
    echo "📤 macOS (Apple Silicon) ZIP 업로드 중..."
    ZIP_ARM64_FILENAME=$(basename "$ZIP_ARM64_PATH")
    
    curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/zip" \
      --data-binary "@$ZIP_ARM64_PATH" \
      "$UPLOAD_URL?name=$ZIP_ARM64_FILENAME" > /dev/null
    
    echo "✅ macOS (Apple Silicon) ZIP 업로드 완료"
fi

# macOS (Intel) DMG 업로드
if [ -f "$DMG_X86_64_PATH" ]; then
    echo "📤 macOS (Intel) DMG 업로드 중..."
    DMG_X86_64_FILENAME=$(basename "$DMG_X86_64_PATH")
    
    curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/octet-stream" \
      --data-binary "@$DMG_X86_64_PATH" \
      "$UPLOAD_URL?name=$DMG_X86_64_FILENAME" > /dev/null
    
    echo "✅ macOS (Intel) DMG 업로드 완료"
fi

# macOS (Intel) ZIP 업로드
if [ -f "$ZIP_X86_64_PATH" ]; then
    echo "📤 macOS (Intel) ZIP 업로드 중..."
    ZIP_X86_64_FILENAME=$(basename "$ZIP_X86_64_PATH")
    
    curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/zip" \
      --data-binary "@$ZIP_X86_64_PATH" \
      "$UPLOAD_URL?name=$ZIP_X86_64_FILENAME" > /dev/null
    
    echo "✅ macOS (Intel) ZIP 업로드 완료"
fi

# Windows EXE 업로드
if [ -f "$WINDOWS_EXE_PATH" ]; then
    echo "📤 Windows EXE 업로드 중..."
    WINDOWS_EXE_FILENAME=$(basename "$WINDOWS_EXE_PATH")
    
    curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/octet-stream" \
      --data-binary "@$WINDOWS_EXE_PATH" \
      "$UPLOAD_URL?name=$WINDOWS_EXE_FILENAME" > /dev/null
    
    echo "✅ Windows EXE 업로드 완료"
fi

# 12. 정리
rm "$RELEASE_NOTES_FILE"

echo ""
echo "=================================================="
echo "✅ 릴리즈 $TAG 배포 완료!"
echo "=================================================="
echo ""
echo "🔗 릴리즈 페이지: https://github.com/$GITHUB_REPO/releases/tag/$TAG"
echo ""
echo "다음 단계:"
echo "1. 코드에서 CURRENT_VERSION을 '$VERSION'으로 업데이트"
echo "2. pyproject.toml의 버전 업데이트"
echo "3. CHANGELOG.md 업데이트"
echo ""

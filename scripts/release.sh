#!/bin/bash

# GitHub Release Script
# 사용법: ./scripts/release.sh 0.1.0

set -e  # 에러 발생 시 스크립트 중단

# ================================================
# 프로젝트 설정
# ================================================
PROJECT_NAME="nfcify"
GITHUB_REPO="nfcify/nfcify"

# 배포 파일 경로
DMG_PATH="dist/nfcify.dmg"
APP_PATH="dist/nfcify.app.zip"

# GitHub Personal Access Token (환경변수에서 읽기)
# export GITHUB_TOKEN="your_token_here" 또는 ~/.bashrc, ~/.zshrc에 추가
# 토큰 생성: https://github.com/settings/tokens (repo 권한 필요)
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
# ================================================

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "❌ 버전을 입력해주세요."
    echo "사용법: $0 <version>"
    echo "예시: $0 0.1.0"
    exit 1
fi

TAG="v$VERSION"

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

if [ ! -f "$DMG_PATH" ]; then
    echo "❌ $DMG_PATH 파일을 찾을 수 없습니다."
    echo "💡 먼저 DMG 파일을 빌드해주세요."
    exit 1
fi

if [ ! -f "$APP_PATH" ]; then
    echo "⚠️  $APP_PATH 파일을 찾을 수 없습니다."
    read -p "APP 파일 없이 계속하시겠습니까? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    APP_PATH=""
fi

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
echo "DMG: $DMG_PATH"
if [ -n "$APP_PATH" ]; then
    echo "APP: $APP_PATH"
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
RELEASE_BODY=$(jq -Rs . < "$RELEASE_NOTES_FILE")

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
echo "📤 DMG 파일 업로드 중..."

UPLOAD_URL="https://uploads.github.com/repos/$GITHUB_REPO/releases/$RELEASE_ID/assets"
DMG_FILENAME=$(basename "$DMG_PATH")

curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@$DMG_PATH" \
  "$UPLOAD_URL?name=$DMG_FILENAME" > /dev/null

echo "✅ DMG 파일 업로드 완료"

# APP 파일이 있으면 업로드
if [ -n "$APP_PATH" ]; then
    echo ""
    echo "📤 APP 파일 업로드 중..."
    APP_FILENAME=$(basename "$APP_PATH")

    curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/zip" \
      --data-binary "@$APP_PATH" \
      "$UPLOAD_URL?name=$APP_FILENAME" > /dev/null

    echo "✅ APP 파일 업로드 완료"
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

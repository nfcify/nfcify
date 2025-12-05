# NFCify

macOS와 Windows에서 파일명의 유니코드 정규화(NFD → NFC 변환)를 자동으로 처리하는 앱

> macOS는 파일명을 NFD 형식으로 저장하여 한글 등이 분리되는 문제가 발생합니다.  
> NFCify는 이를 NFC 형식으로 자동 변환하여 해결합니다.

## 📥 다운로드 및 설치

**[최신 버전 다운로드](https://github.com/nfcify/nfcify/releases/latest)**

### macOS

1. 사용 중인 Mac에 맞는 ZIP 파일 다운로드
   - **Apple Silicon** (M1/M2/M3): `arm64` 버전
   - **Intel Mac**: `x86_64` 버전

2. ZIP 파일 다운로드 → 자동 압축 해제

3. `NFCify.app`을 Applications 폴더로 이동

4. 앱을 더블클릭하여 실행 시도 (보안 경고가 나타남)

5. **시스템 설정** → **개인정보 보호 및 보안** → **보안** 탭으로 이동

6. 하단의 "확인되지 않은 개발자" 메시지 옆의 **"확인 없이 열기"** 버튼 클릭

7. 확인 창에서 **"열기"** 클릭

> **참고**: 이 과정은 처음 한 번만 필요합니다.  
> 이후에는 일반 앱처럼 더블클릭으로 실행할 수 있습니다.

### Windows

1. `NFCify-{version}-windows.exe` 다운로드
2. 실행 파일 실행
3. Windows Defender 경고 시: "추가 정보" → "실행"

## ✨ 주요 기능

- ✅ **자동 파일명 변환**: NFD → NFC 실시간 자동 변환
- ✅ **다중 폴더 감시**: 최대 5개 폴더 동시 감시
- ✅ **로그인 시 자동 실행**: 시스템 시작 시 자동 실행
- ✅ **다국어 지원**: 한국어, English

## 💡 문제 해결

<details>
<summary><b>macOS: "악성 코드 확인 불가" 경고</b></summary>

위의 설치 방법 4-7단계를 따라주세요:

1. 앱을 더블클릭하여 실행 시도
2. **시스템 설정** → **개인정보 보호 및 보안** → **보안**
3. **"확인 없이 열기"** 버튼 클릭
4. 확인 창에서 **"열기"** 클릭

**또는 터미널 사용**:
```bash
xattr -cr /Applications/NFCify.app && open /Applications/NFCify.app
```
</details>

<details>
<summary><b>로그인 시 자동 실행이 작동하지 않음</b></summary>

- **macOS**: 시스템 설정 → 일반 → 로그인 항목에서 NFCify 확인
- **Windows**: 작업 관리자 → 시작 프로그램에서 NFCify 활성화 확인
</details>

## 🐛 버그 리포트

문제 발생 시 [Issues](https://github.com/nfcify/nfcify/issues)에 등록해주세요.

## 📄 라이선스

MIT License

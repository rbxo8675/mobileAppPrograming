# Google 로그인 설정 가이드

Google 로그인이 실패하는 이유는 Firebase Console에 앱의 SHA-1 fingerprint가 등록되지 않았기 때문입니다.

## 1. SHA-1 Fingerprint 가져오기

### Windows PowerShell에서 실행:
```powershell
cd android
.\gradlew signingReport
```

### 출력에서 찾기:
```
Variant: debug
Config: debug
Store: C:\Users\YOUR_USER\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD  ← 이 값을 복사
SHA-256: ...
```

## 2. Firebase Console에 SHA-1 등록

1. [Firebase Console](https://console.firebase.google.com) 접속
2. **cooktalk-7de20** 프로젝트 선택
3. 왼쪽 메뉴에서 **⚙️ 프로젝트 설정** 클릭
4. **내 앱** 섹션에서 Android 앱 선택
5. 아래로 스크롤하여 **SHA 인증서 지문** 섹션 찾기
6. **지문 추가** 버튼 클릭
7. 위에서 복사한 SHA-1 값 붙여넣기
8. **저장** 클릭

## 3. google-services.json 다운로드 (선택사항)

Firebase Console에서 새로운 `google-services.json` 파일을 다운로드하여 `android/app/` 폴더에 덮어쓰기

## 4. 앱 재실행

```bash
flutter clean
flutter run -d R3CX205SNQF
```

## 임시 해결책

Google 로그인이 설정되기 전까지는:
- **이메일/비밀번호 로그인** 사용
- **익명 로그인 (둘러보기)** 사용

이 두 가지 방법은 SHA-1 설정 없이도 작동합니다.

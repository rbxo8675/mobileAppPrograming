# 🔥 Firebase 설정 가이드

## 완료된 작업

### ✅ Phase 0-3: 기본 설정 완료
1. **Firebase SDK 설치** (`pubspec.yaml`)
   - firebase_core
   - cloud_firestore
   - firebase_auth
   - firebase_storage
   - google_sign_in
   - cached_network_image
   - flutter_image_compress
   - connectivity_plus

2. **Firebase 초기화 코드** (`lib/main.dart`)
   - Firebase.initializeApp() 추가
   - Firestore 오프라인 캐싱 활성화
   - AuthController Provider 등록

3. **Firebase 서비스 생성**
   - `lib/data/services/auth_service.dart` - 인증 서비스
   - `lib/data/services/firestore_service.dart` - Firestore 헬퍼
   - `lib/data/services/storage_service.dart` - Storage 서비스

4. **Repository 생성**
   - `lib/data/repositories/auth_repository.dart` - 인증 레포지토리
   - `lib/data/repositories/firestore_recipe_repository.dart` - 레시피 Firestore 레포지토리

5. **모델 업데이트**
   - `lib/models/user.dart` - User 클래스 추가 (Firebase 연동)
   - `lib/models/recipe.dart` - Firestore 필드 추가 (toFirestore/fromFirestore)

6. **Controller 생성**
   - `lib/controllers/auth_controller.dart` - 인증 상태 관리

7. **보안 규칙**
   - `firestore.rules` - Firestore 보안 규칙
   - `storage.rules` - Storage 보안 규칙

---

## 🚀 다음 단계: Firebase 콘솔 설정

### 1. Firebase 프로젝트 생성
1. https://console.firebase.google.com/ 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름: `cooktalk-mvc`
4. Google Analytics 활성화 (권장)
5. 프로젝트 생성 완료

### 2. 앱 등록

#### Android 앱 등록
1. Firebase 콘솔 → 프로젝트 설정 → Android 앱 추가
2. Android 패키지 이름: `com.cooktalk.app` (또는 기존 패키지명)
3. SHA-1 인증서 지문 추가 (Google 로그인용)
   ```bash
   # Debug 키 SHA-1 얻기
   keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore
   # 비밀번호: android
   ```
4. `google-services.json` 다운로드
5. `android/app/` 폴더에 `google-services.json` 복사

#### iOS 앱 등록 (선택)
1. Firebase 콘솔 → 프로젝트 설정 → iOS 앱 추가
2. 번들 ID: `com.cooktalk.app`
3. `GoogleService-Info.plist` 다운로드
4. `ios/Runner/` 폴더에 복사

#### Web 앱 등록 (선택)
1. Firebase 콘솔 → 프로젝트 설정 → Web 앱 추가
2. 앱 닉네임: `CookTalk Web`
3. Firebase SDK 구성 복사

### 3. Firebase 옵션 업데이트

FlutterFire CLI로 자동 생성:
```bash
# FlutterFire CLI 설치 (이미 완료)
dart pub global activate flutterfire_cli

# Firebase 프로젝트 구성
flutterfire configure --project=cooktalk-mvc
```

또는 수동으로 `lib/core/config/firebase_options.dart` 파일 업데이트:
- Web/Android/iOS의 API Key, App ID 등 실제 값으로 교체

### 4. Firebase Authentication 활성화

1. Firebase 콘솔 → Authentication → 시작하기
2. 로그인 제공업체 활성화:
   - **이메일/비밀번호**: 사용 설정
   - **Google**: 사용 설정
     - 프로젝트 공개용 이름 입력
     - 지원 이메일 선택
   - **익명**: 사용 설정 (선택)

### 5. Cloud Firestore 활성화

1. Firebase 콘솔 → Firestore Database → 데이터베이스 만들기
2. **프로덕션 모드에서 시작** 선택
3. 위치 선택: `asia-northeast3` (서울)
4. 데이터베이스 만들기 완료
5. 규칙 탭 → `firestore.rules` 내용 복사/붙여넣기
6. 게시 클릭

### 6. Cloud Storage 활성화

1. Firebase 콘솔 → Storage → 시작하기
2. **프로덕션 모드에서 시작** 선택
3. 위치 선택: `asia-northeast3` (서울)
4. 완료
5. Rules 탭 → `storage.rules` 내용 복사/붙여넣기
6. 게시 클릭

### 7. Firestore 인덱스 생성

Firebase 콘솔 → Firestore Database → 색인 탭

**복합 색인 추가:**

1. **recipes 컬렉션** - 공개 레시피 정렬
   - 컬렉션 ID: `recipes`
   - 필드: `isPublic` (오름차순), `createdAt` (내림차순)
   
2. **recipes 컬렉션** - 인기 레시피
   - 컬렉션 ID: `recipes`
   - 필드: `isPublic` (오름차순), `likeCount` (내림차순)

3. **recipes 컬렉션** - 작성자별 레시피
   - 컬렉션 ID: `recipes`
   - 필드: `authorId` (오름차순), `createdAt` (내림차순)

4. **bookmarks 컬렉션** - 사용자 북마크
   - 컬렉션 ID: `bookmarks`
   - 필드: `userId` (오름차순), `createdAt` (내림차순)

> 앱 실행 중 인덱스 오류가 발생하면 Firebase 콘솔이 자동으로 인덱스 생성 링크를 제공합니다.

---

## 📱 Android 설정

### `android/build.gradle`
```gradle
buildscript {
    dependencies {
        // Firebase 추가
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### `android/app/build.gradle`
```gradle
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'dev.flutter.flutter-gradle-plugin'
    id 'com.google.gms.google-services'  // 추가
}

android {
    defaultConfig {
        minSdkVersion 21  // Firebase 최소 버전
    }
}
```

### MultiDex 활성화 (선택)
`android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        multiDexEnabled true
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

---

## 🍎 iOS 설정 (선택)

### `ios/Podfile`
```ruby
platform :ios, '13.0'  # Firebase 최소 버전

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

### Pod 설치
```bash
cd ios
pod install
cd ..
```

---

## 🌐 Web 설정 (선택)

### `web/index.html`
```html
<body>
  <!-- Firebase SDK 추가 -->
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-firestore-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-storage-compat.js"></script>

  <script>
    // Firebase 구성 (Firebase 콘솔에서 복사)
    const firebaseConfig = {
      apiKey: "YOUR_API_KEY",
      authDomain: "cooktalk-mvc.firebaseapp.com",
      projectId: "cooktalk-mvc",
      storageBucket: "cooktalk-mvc.appspot.com",
      messagingSenderId: "YOUR_SENDER_ID",
      appId: "YOUR_APP_ID"
    };

    firebase.initializeApp(firebaseConfig);
  </script>

  <script src="main.dart.js" type="application/javascript"></script>
</body>
```

---

## ✅ 설정 확인

### 1. 앱 실행
```bash
flutter run
```

### 2. Firebase 연결 테스트
- 앱 실행 시 로그 확인:
  ```
  [INFO] Firebase initialized successfully
  [INFO] Firestore offline persistence enabled
  ```

### 3. 인증 테스트
- 회원가입/로그인 기능 테스트
- Firebase 콘솔 → Authentication → Users에서 사용자 확인

### 4. Firestore 테스트
- 레시피 생성 테스트
- Firebase 콘솔 → Firestore Database에서 데이터 확인

---

## 🔧 트러블슈팅

### 1. "Firebase app has not been initialized"
- `main.dart`에서 `Firebase.initializeApp()` 호출 확인
- `firebase_options.dart` 파일 존재 확인

### 2. Google 로그인 실패 (Android)
- SHA-1 인증서 지문 등록 확인
- `google-services.json` 파일 위치 확인
- Google 로그인 제공업체 활성화 확인

### 3. Firestore 권한 오류
- `firestore.rules` 배포 확인
- 로그인 상태 확인 (인증 필요한 경우)

### 4. Storage 업로드 실패
- `storage.rules` 배포 확인
- 파일 크기 제한 (10MB) 확인
- 파일 형식 제한 (이미지만) 확인

---

## 📚 추가 작업 필요

### Phase 5: 실시간 소셜 기능
- [ ] FeedRepository Firestore 전환
- [ ] CommentRepository 생성
- [ ] FollowRepository 생성
- [ ] 실시간 스트림 UI 연결

### Phase 6: 요리 세션 동기화
- [ ] CookingSessionRepository Firestore 전환
- [ ] 멀티 디바이스 지원
- [ ] 완료 히스토리 동기화

### Phase 7: FCM 푸시 알림
- [ ] FCM 설정
- [ ] 토큰 관리
- [ ] 알림 핸들러 구현

---

## 📞 문의 및 지원

Firebase 관련 문제 발생 시:
1. Firebase 콘솔 로그 확인
2. Flutter 앱 로그 확인 (`Logger.info/error`)
3. Firebase 공식 문서: https://firebase.google.com/docs/flutter

---

**작성일**: 2025-10-15
**버전**: 1.0

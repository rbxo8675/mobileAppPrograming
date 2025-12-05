# 🔥 CookTalk Firebase 마이그레이션 계획서

## 📋 개요

현재 CookTalk은 로컬 SQLite 데이터베이스를 사용하고 있습니다. 이 문서는 Firebase를 백엔드 데이터베이스로 마이그레이션하는 전체 계획을 설명합니다.

**목표**: 실시간 동기화, 멀티 디바이스 지원, 소셜 기능 강화, 클라우드 저장소 활용

---

## 🎯 마이그레이션 범위

### Firebase 서비스 활용
- **Firestore**: 메인 데이터베이스 (레시피, 사용자, 댓글, 팔로우 등)
- **Firebase Authentication**: 사용자 인증 (이메일, Google, 익명 로그인)
- **Firebase Storage**: 이미지/미디어 파일 저장
- **Firebase Cloud Messaging**: 푸시 알림 (타이머, 팔로우, 댓글)
- **Firebase Analytics**: 사용자 행동 분석
- **Cloud Functions** (선택): 서버 사이드 로직 (알림, 검색 인덱싱)

---

## 📊 현재 상태 분석

### 현재 데이터 구조 (SQLite)
```
lib/data/
├── database/
│   └── app_database.dart          # SQLite 로컬 DB
├── repositories/
│   ├── recipe_repository.dart     # 레시피 CRUD
│   ├── feed_repository.dart       # 피드/팔로우
│   ├── cooking_session_repository.dart  # 세션 (로컬만)
│   └── search_repository.dart     # 검색
└── services/
    ├── recipe_service.dart        # 목 데이터
    ├── gemini_service.dart        # AI
    └── [기타 서비스들...]
```

### 현재 모델
- `Recipe`: 레시피 정보 (로컬 저장)
- `User`: 사용자 정보 (목 데이터)
- `FeedPost`: 피드 포스트 (목 데이터)
- `Comment`: 댓글 (로컬만)
- `CookingSession`: 요리 세션 (SharedPreferences)
- `Bookmark`, `Follow`: 로컬 추적

---

## 🏗️ 새로운 Firebase 아키텍처

### Firestore 컬렉션 구조

```
users/                                 # 사용자 컬렉션
  {userId}/
    - uid: string
    - email: string
    - displayName: string
    - photoURL: string
    - bio: string
    - followerCount: number
    - followingCount: number
    - createdRecipeCount: number
    - preferences: map
      - locale: string
      - favoriteTags: array
      - weeklyGoal: number
    - createdAt: timestamp
    - updatedAt: timestamp

recipes/                               # 레시피 컬렉션
  {recipeId}/
    - id: string
    - authorId: string (userId 참조)
    - title: string
    - description: string
    - imagePath: string (Storage URL)
    - ingredients: array<string>
    - steps: array<map>
      - order: number
      - instruction: string
      - durationSec: number
      - mediaUrl: string
    - tags: array<string>
    - hashtags: array<string>
    - servings: number
    - durationMinutes: number
    - difficulty: string
    - rating: number
    - likeCount: number
    - bookmarkCount: number
    - completedCount: number
    - viewCount: number
    - isPublic: boolean
    - createdAt: timestamp
    - updatedAt: timestamp

posts/                                 # 소셜 피드 포스트
  {postId}/
    - id: string
    - userId: string
    - recipeId: string (선택)
    - content: string
    - imageUrls: array<string>
    - likeCount: number
    - commentCount: number
    - shareCount: number
    - createdAt: timestamp

comments/                              # 댓글 컬렉션
  {commentId}/
    - id: string
    - postId: string (또는 recipeId)
    - userId: string
    - content: string
    - replyToId: string (대댓글용)
    - likeCount: number
    - createdAt: timestamp
    - updatedAt: timestamp

cookingSessions/                       # 요리 세션 (멀티 디바이스 동기화)
  {sessionId}/
    - id: string
    - userId: string
    - recipeId: string
    - currentStep: number
    - status: string (IN_PROGRESS/PAUSED/COMPLETED)
    - timers: array<map>
    - startedAt: timestamp
    - completedAt: timestamp
    - elapsedSeconds: number
    - rating: number
    - notes: string
    - photoUrls: array<string>

follows/                               # 팔로우 관계
  {followId}/
    - followerId: string
    - followeeId: string
    - createdAt: timestamp

bookmarks/                             # 북마크
  {bookmarkId}/
    - userId: string
    - recipeId: string
    - collectionName: string
    - createdAt: timestamp

likes/                                 # 좋아요 (레시피/포스트)
  {likeId}/
    - userId: string
    - targetId: string (recipeId or postId)
    - targetType: string (recipe/post/comment)
    - createdAt: timestamp

notifications/                         # 알림
  {notificationId}/
    - userId: string
    - type: string (FOLLOW/COMMENT/LIKE/TIMER)
    - title: string
    - body: string
    - imageUrl: string
    - data: map
    - read: boolean
    - createdAt: timestamp
```

### Firebase Storage 구조
```
/users/{userId}/
  - profile.jpg
  
/recipes/{recipeId}/
  - main.jpg
  - step1.jpg
  - step2.jpg

/posts/{postId}/
  - image1.jpg
  - image2.jpg

/sessions/{sessionId}/
  - result.jpg
```

---

## 📝 마이그레이션 Phase

### Phase 0: 환경 설정
**목표**: Firebase 프로젝트 생성 및 Flutter 앱 연동

#### 작업 항목
1. ✅ Firebase 프로젝트 생성
   - Firebase Console에서 새 프로젝트 생성
   - Android/iOS/Web 앱 등록

2. ✅ Firebase SDK 설치
   ```yaml
   dependencies:
     firebase_core: ^3.0.0
     cloud_firestore: ^5.0.0
     firebase_auth: ^5.0.0
     firebase_storage: ^12.0.0
     firebase_messaging: ^15.0.0
     firebase_analytics: ^11.0.0
   ```

3. ✅ Firebase 초기화
   ```dart
   // lib/main.dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

4. ✅ 환경 변수 설정
   - `.env` 파일에 Firebase 설정 추가
   - `google-services.json` (Android)
   - `GoogleService-Info.plist` (iOS)

#### 파일 생성
```
lib/
  core/
    config/
      firebase_options.dart  # 새 파일
```

---

### Phase 1: 인증 시스템 구축
**목표**: Firebase Authentication 통합

#### 작업 항목
1. ✅ AuthService 생성
   - 이메일/비밀번호 로그인
   - Google 소셜 로그인
   - 익명 로그인
   - 로그아웃/회원탈퇴

2. ✅ AuthRepository 생성
   - User 상태 관리 (StreamProvider)
   - 로그인 상태 추적

3. ✅ AuthController 생성
   - UI와 연결
   - 에러 핸들링

4. ✅ 로그인/회원가입 UI 생성
   - LoginView
   - SignUpView
   - ProfileSetupView

#### 파일 변경
```
lib/
  data/
    services/
      auth_service.dart          # 새 파일
    repositories/
      auth_repository.dart       # 새 파일
  controllers/
    auth_controller.dart         # 새 파일
  views/
    auth/
      login_view.dart            # 새 파일
      signup_view.dart           # 새 파일
      profile_setup_view.dart    # 새 파일
  models/
    user.dart                    # 수정 (Firebase User 연동)
```

#### 수용 기준
- 사용자가 이메일/비밀번호로 회원가입/로그인 가능
- Google 계정으로 로그인 가능
- 익명 로그인 후 계정 전환 가능
- 로그인 상태가 앱 재시작 시 유지됨

---

### Phase 2: Firestore 데이터 모델 마이그레이션
**목표**: SQLite → Firestore 데이터 마이그레이션

#### 작업 항목
1. ✅ Firestore 데이터 모델 정의
   - `toFirestore()`, `fromFirestore()` 메서드 추가
   - 모든 모델 클래스 업데이트

2. ✅ FirestoreService 생성
   - CRUD 헬퍼 메서드
   - 실시간 스트림 리스너
   - 배치 작업 지원

3. ✅ Recipe → Firestore 마이그레이션
   - RecipeRepository 업데이트
   - FirestoreRecipeRepository 생성

4. ✅ 오프라인 지원 설정
   - Firestore 캐시 활성화
   - `persistenceEnabled: true`

#### 파일 변경
```
lib/
  data/
    services/
      firestore_service.dart             # 새 파일
    repositories/
      firestore_recipe_repository.dart   # 새 파일
      firestore_feed_repository.dart     # 새 파일
      firestore_session_repository.dart  # 새 파일
  models/
    recipe.dart                          # 수정 (+ toFirestore/fromFirestore)
    feed_post.dart                       # 수정
    cooking_session.dart                 # 수정
    comment.dart                         # 수정
    bookmark.dart                        # 수정
    follow.dart                          # 수정
```

#### 마이그레이션 스크립트
```dart
// tools/migrate_to_firestore.dart
Future<void> migrateLocalDataToFirestore() async {
  final localDb = AppDatabase();
  final firestoreRepo = FirestoreRecipeRepository();
  
  final localRecipes = await localDb.getAllRecipes();
  
  for (final recipe in localRecipes) {
    await firestoreRepo.createRecipe(recipe);
  }
  
  print('Migrated ${localRecipes.length} recipes');
}
```

#### 수용 기준
- 모든 레시피가 Firestore에 저장됨
- 실시간 업데이트가 UI에 반영됨
- 오프라인에서 읽기/쓰기 가능 (캐시 활용)
- 로컬 데이터가 Firestore로 마이그레이션됨

---

### Phase 3: Firebase Storage 통합
**목표**: 이미지/미디어 파일을 Cloud Storage에 업로드

#### 작업 항목
1. ✅ StorageService 생성
   - 이미지 업로드/다운로드
   - 썸네일 생성
   - URL 가져오기

2. ✅ ImagePicker 통합
   - 레시피 이미지 선택
   - 프로필 사진 업로드
   - 요리 완료 사진 업로드

3. ✅ 캐싱 전략
   - cached_network_image 패키지 사용
   - 로컬 캐시 우선 로딩

#### 파일 변경
```
lib/
  data/
    services/
      storage_service.dart       # 새 파일
  core/
    utils/
      image_compressor.dart      # 새 파일
```

#### 수용 기준
- 레시피 이미지가 Storage에 업로드됨
- 이미지 URL이 Firestore에 저장됨
- 이미지 로딩 시 캐싱 적용
- 업로드 진행률 표시

---

### Phase 4: 실시간 소셜 기능 강화
**목표**: 피드, 댓글, 팔로우를 Firestore로 실시간 동기화

#### 작업 항목
1. ✅ FeedRepository → Firestore
   - 실시간 피드 스트림
   - 페이지네이션 (limit/startAfter)
   - 팔로잉 필터링

2. ✅ CommentRepository → Firestore
   - 댓글 CRUD
   - 실시간 댓글 업데이트
   - 대댓글 지원

3. ✅ FollowRepository → Firestore
   - 팔로우/언팔로우
   - 팔로워/팔로잉 목록
   - 카운트 업데이트 (Cloud Functions 권장)

4. ✅ LikeRepository → Firestore
   - 좋아요/취소
   - 중복 방지 (unique constraint)

#### 파일 변경
```
lib/
  data/
    repositories/
      feed_repository.dart       # 수정 (Firestore 전환)
      comment_repository.dart    # 새 파일
      follow_repository.dart     # 새 파일
      like_repository.dart       # 새 파일
```

#### 수용 기준
- 피드가 실시간으로 업데이트됨
- 댓글 작성 시 즉시 UI 반영
- 팔로우 시 카운트 즉시 업데이트
- 좋아요 중복 클릭 방지

---

### Phase 5: 요리 세션 동기화
**목표**: CookingSession을 Firestore로 동기화하여 멀티 디바이스 지원

#### 작업 항목
1. ✅ CookingSessionRepository → Firestore
   - 세션 생성/저장/복원
   - 실시간 진행도 추적
   - 타이머 상태 동기화

2. ✅ 멀티 디바이스 지원
   - 다른 기기에서 세션 이어하기
   - 충돌 해결 전략 (최신 업데이트 우선)

3. ✅ 완료 히스토리 Firestore 저장
   - CompletedRecipesView 업데이트
   - 통계 실시간 집계

#### 수용 기준
- 요리 세션이 클라우드에 자동 저장됨
- 다른 기기에서 세션 복원 가능
- 완료 히스토리가 Firestore에 저장됨

---

### Phase 6: 푸시 알림 (FCM)
**목표**: Firebase Cloud Messaging으로 푸시 알림 전송

#### 작업 항목
1. ✅ FCM 설정
   - 토큰 관리 (User 문서에 저장)
   - 권한 요청 플로우

2. ✅ NotificationService 생성
   - 포그라운드/백그라운드 알림 처리
   - 딥링크 라우팅

3. ✅ 알림 트리거 설정
   - 타이머 완료 알림 (로컬)
   - 팔로워 알림 (Cloud Functions)
   - 댓글/좋아요 알림 (Cloud Functions)

#### 파일 변경
```
lib/
  data/
    services/
      fcm_service.dart           # 새 파일 (기존 notification_service.dart 통합)
```

#### 수용 기준
- 타이머 완료 시 알림 수신
- 팔로우 시 상대방에게 알림 전송
- 댓글 작성 시 포스트 작성자에게 알림

---

### Phase 7: 검색 및 인덱싱
**목표**: Firestore 쿼리 최적화 및 검색 기능 강화

#### 작업 항목
1. ✅ Firestore 복합 인덱스 생성
   - 태그별 검색
   - 정렬 + 필터링

2. ✅ Algolia 통합 (선택)
   - 전체 텍스트 검색
   - 자동완성

3. ✅ 추천 알고리즘 최적화
   - 사용자 행동 기반 추천
   - Firebase Analytics 데이터 활용

#### 파일 변경
```
lib/
  data/
    repositories/
      search_repository.dart     # 수정 (Firestore 쿼리)
```

---

### Phase 8: Cloud Functions (서버 사이드 로직)
**목표**: 백엔드 로직을 Cloud Functions로 이전

#### 작업 항목
1. ✅ 카운트 업데이트 함수
   - 팔로워/팔로잉 카운트
   - 좋아요 카운트
   - 댓글 카운트

2. ✅ 알림 전송 함수
   - 팔로우 알림
   - 댓글 알림
   - 좋아요 알림

3. ✅ 검색 인덱싱 함수
   - Algolia 인덱스 업데이트
   - 태그 자동 생성

#### 파일 생성
```
functions/
  index.js
  src/
    triggers/
      onFollowCreated.js
      onCommentCreated.js
      onLikeCreated.js
    scheduled/
      updateRecommendations.js
```

---

### Phase 9: 성능 최적화 및 테스트
**목표**: Firestore 읽기/쓰기 최적화, 비용 절감

#### 작업 항목
1. ✅ 캐싱 전략 수립
   - 자주 읽는 데이터 로컬 캐싱
   - 오프라인 우선 전략

2. ✅ 페이지네이션 구현
   - 무한 스크롤
   - 커서 기반 페이징

3. ✅ 보안 규칙 강화
   - `firestore.rules` 작성
   - 읽기/쓰기 권한 세분화

4. ✅ 테스트 작성
   - Firestore 유닛 테스트
   - 통합 테스트 (Emulator Suite)

#### 파일 생성
```
firestore.rules
storage.rules

test/
  firebase_test.dart
```

---

### Phase 10: 배포 및 모니터링
**목표**: 프로덕션 환경 배포 및 모니터링 설정

#### 작업 항목
1. ✅ Firebase Crashlytics 통합
   - 크래시 리포팅
   - 커스텀 로그

2. ✅ Firebase Performance Monitoring
   - 네트워크 지연 추적
   - 화면 렌더링 성능

3. ✅ Firebase Analytics 이벤트 추가
   - 사용자 행동 추적
   - 전환율 분석

4. ✅ A/B 테스트 (Firebase Remote Config)
   - 기능 플래그
   - UI 실험

---

## 🛠️ 기술 스택 업데이트

### 추가 의존성
```yaml
dependencies:
  # Firebase Core
  firebase_core: ^3.0.0
  
  # Firebase Services
  cloud_firestore: ^5.0.0
  firebase_auth: ^5.0.0
  firebase_storage: ^12.0.0
  firebase_messaging: ^15.0.0
  firebase_analytics: ^11.0.0
  firebase_crashlytics: ^4.0.0
  firebase_performance: ^0.10.0
  firebase_remote_config: ^5.0.0
  
  # Google Sign-In
  google_sign_in: ^6.2.0
  
  # 이미지 캐싱
  cached_network_image: ^3.3.0
  
  # 이미지 압축
  flutter_image_compress: ^2.0.0
  
  # 오프라인 지원 (기존)
  connectivity_plus: ^5.0.0
```

---

## 📈 예상 Firestore 비용 (월)

### 무료 티어 (Spark Plan)
- 문서 읽기: 50,000/일
- 문서 쓰기: 20,000/일
- 문서 삭제: 20,000/일
- 저장소: 1GB
- 네트워크: 10GB/월

### 예상 사용량 (소규모 사용자 기준)
- 일일 활성 사용자 100명
- 사용자당 평균 읽기: 50회
- 사용자당 평균 쓰기: 10회

**총 예상**:
- 읽기: 5,000/일 (무료 범위 내)
- 쓰기: 1,000/일 (무료 범위 내)

---

## 🔒 보안 규칙 예시

### firestore.rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 사용자는 자기 문서만 읽기/쓰기
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // 레시피는 모두 읽기 가능, 작성자만 수정/삭제
    match /recipes/{recipeId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.authorId;
    }
    
    // 댓글은 모두 읽기 가능, 작성자만 수정/삭제
    match /comments/{commentId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }
    
    // 세션은 본인만 접근
    match /cookingSessions/{sessionId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
    
    // 팔로우는 본인만 생성/삭제
    match /follows/{followId} {
      allow read: if true;
      allow create: if request.auth.uid == request.resource.data.followerId;
      allow delete: if request.auth.uid == resource.data.followerId;
    }
  }
}
```

---

## 🚀 롤아웃 전략

### Stage 1: 개발 환경 (1-2주)
- Firebase 프로젝트 생성 (dev)
- Phase 0-3 완료
- 내부 테스트

### Stage 2: 베타 테스트 (2주)
- Phase 4-6 완료
- 베타 테스터 초대 (10-20명)
- 피드백 수집

### Stage 3: 소프트 런칭 (1주)
- Phase 7-9 완료
- 제한된 사용자에게 오픈
- 성능 모니터링

### Stage 4: 전체 배포 (지속)
- Phase 10 완료
- 모든 사용자에게 오픈
- 지속적 개선

---

## ✅ 마이그레이션 체크리스트

### Phase 0: 환경 설정
- [ ] Firebase 프로젝트 생성 (dev/prod)
- [ ] Firebase SDK 설치
- [ ] google-services.json / GoogleService-Info.plist 추가
- [ ] Firebase 초기화 코드 작성

### Phase 1: 인증
- [ ] AuthService 구현
- [ ] 로그인/회원가입 UI
- [ ] Google 로그인 연동
- [ ] 익명 로그인 지원

### Phase 2: Firestore
- [ ] 모델 클래스 업데이트 (toFirestore/fromFirestore)
- [ ] FirestoreService 구현
- [ ] RecipeRepository Firestore 전환
- [ ] 오프라인 캐싱 활성화

### Phase 3: Storage
- [ ] StorageService 구현
- [ ] 이미지 업로드 기능
- [ ] cached_network_image 통합

### Phase 4: 소셜 기능
- [ ] FeedRepository Firestore 전환
- [ ] CommentRepository 구현
- [ ] FollowRepository 구현
- [ ] LikeRepository 구현

### Phase 5: 세션 동기화
- [ ] CookingSessionRepository Firestore 전환
- [ ] 멀티 디바이스 지원
- [ ] 완료 히스토리 동기화

### Phase 6: 푸시 알림
- [ ] FCM 토큰 관리
- [ ] 포그라운드/백그라운드 알림 처리
- [ ] 딥링크 라우팅

### Phase 7: 검색
- [ ] Firestore 인덱스 생성
- [ ] 검색 쿼리 최적화
- [ ] (선택) Algolia 통합

### Phase 8: Cloud Functions
- [ ] 카운트 업데이트 함수
- [ ] 알림 전송 함수
- [ ] 검색 인덱싱 함수

### Phase 9: 최적화
- [ ] firestore.rules 작성
- [ ] storage.rules 작성
- [ ] 페이지네이션 구현
- [ ] 테스트 작성

### Phase 10: 배포
- [ ] Crashlytics 통합
- [ ] Performance Monitoring
- [ ] Analytics 이벤트 추가
- [ ] Remote Config 설정

---

## 📚 참고 자료

### 공식 문서
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Data Modeling](https://firebase.google.com/docs/firestore/data-model)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

### 모범 사례
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Offline Data for Web](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [Firebase Performance Tips](https://firebase.google.com/docs/perf-mon/get-started-flutter)

---

## 🎯 성공 지표

### 기술 지표
- Firestore 읽기/쓰기 횟수 < 무료 티어 제한
- 평균 응답 시간 < 500ms
- 크래시 발생률 < 0.5%
- 오프라인 모드 동작률 > 95%

### 사용자 지표
- 회원가입률 > 60%
- DAU/MAU > 30%
- 레시피 공유율 > 20%
- 세션 완료율 > 50%

---

## 🔧 알려진 제약사항

### Firestore 제한
- 단일 문서 크기: 1MB
- 복합 쿼리 제한: 최대 100개 인덱스
- 실시간 리스너: 디바이스당 100개

### 해결 방법
- 큰 데이터는 Storage 사용
- 쿼리 최적화 및 페이지네이션
- 리스너 정리 및 재사용

---

## 🎉 결론

이 마이그레이션을 통해 CookTalk은:
1. **실시간 동기화**: 멀티 디바이스에서 즉시 반영
2. **확장성**: 사용자 증가에 따라 자동 스케일링
3. **오프라인 지원**: 네트워크 없이도 작동
4. **소셜 기능 강화**: 실시간 피드, 알림, 팔로우
5. **운영 편의성**: 백엔드 관리 부담 최소화

**예상 기간**: 4-6주 (Phase 0-10 순차 진행)

---

**작성일**: 2025-10-13  
**최종 수정**: 2025-10-13  
**버전**: 1.0

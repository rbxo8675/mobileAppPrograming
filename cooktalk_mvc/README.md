# CookTalk - AI-Powered Recipe Social App

Flutter 기반의 레시피 공유 소셜 앱으로, Gemini AI를 활용한 스마트 요리 도우미 기능을 제공합니다.

## 주요 기능

### 🍳 레시피 관리
- **탐색**: 추천 레시피 탐색
- **인기**: 트렌딩 레시피 확인
- **내 레시피**: 좋아요/북마크한 레시피 관리

### 🤖 AI 기능 (Gemini 연동)
- **YouTube 레시피 추출**: 유튜브 영상에서 레시피 자동 추출
  - 영상 제목, 설명, 자막 분석
  - 재료, 조리 단계, 시간 등 구조화된 데이터 생성
- **요리 도우미 챗봇**: 실시간 요리 중 질문/답변
  - 재료 대체 추천
  - 조리 팁 제공
  - 시간/분량 조절 가이드

### 📱 소셜 기능
- **피드**: 다른 사용자의 레시피 공유 확인
- **좋아요/북마크**: 관심있는 레시피 저장
- **프로필**: 개인 레시피 관리

## 프로젝트 구조

```
lib/
├── core/                      # 핵심 유틸리티
│   ├── config/               # 앱 설정 (API 키 등)
│   ├── constants/            # 상수 정의
│   ├── errors/               # 예외 처리
│   └── utils/                # 로깅 등
├── data/                     # 데이터 레이어
│   ├── repositories/         # Repository 패턴
│   └── services/             # API 서비스 (Gemini, YouTube)
├── models/                   # 데이터 모델
├── controllers/              # 상태 관리 (Provider)
├── views/                    # 화면 (View)
└── widgets/                  # 재사용 위젯
```

## 아키텍처

**MVC (Model-View-Controller) 패턴**
- **Model**: 데이터 모델 및 비즈니스 로직
- **View**: UI 화면 구성
- **Controller**: 상태 관리 (Provider 사용)

**추가 패턴**
- Repository 패턴: 데이터 소스 추상화
- Service 레이어: 외부 API 통신

## 설정 방법

### 1. 의존성 설치

```bash
flutter pub get
```

### 2. 환경 변수 설정

`.env.example`을 복사하여 `.env` 파일 생성:

```bash
cp .env.example .env
```

`.env` 파일에 Gemini API 키 입력:

```env
GEMINI_API_KEY=your_actual_api_key_here
DEBUG_MODE=true
```

### 3. Gemini API 키 발급

1. [Google AI Studio](https://makersuite.google.com/app/apikey) 방문
2. API 키 생성
3. `.env` 파일에 키 입력

### 4. 앱 실행

```bash
flutter run
```

## 주요 의존성

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2                    # 상태 관리
  google_generative_ai: ^0.4.0        # Gemini AI
  youtube_explode_dart: ^2.0.0        # YouTube 데이터 추출
  flutter_dotenv: ^5.1.0              # 환경 변수 관리
  http: ^1.2.2                        # HTTP 요청
  url_launcher: ^6.3.0                # URL 실행
  file_picker: ^8.0.0                 # 파일 선택
```

## 사용 방법

### YouTube 레시피 가져오기

1. 내 레시피 탭 이동
2. + 버튼 클릭 → "YouTube에서 가져오기"
3. YouTube URL 입력
4. AI가 자동으로 레시피 추출

### AI 요리 도우미 사용

1. 레시피 상세 화면 진입
2. "AI 도우미" 버튼 클릭
3. 요리 중 궁금한 점 질문
   - "이 재료 대신 뭘 써도 돼?"
   - "조리 시간을 줄이려면?"
   - "양을 2배로 늘리려면?"

## 개발 로드맵

- [x] MVC 아키텍처 구현
- [x] Gemini AI 통합
- [x] YouTube 레시피 추출
- [x] 요리 도우미 챗봇
- [x] Repository 패턴 적용
- [x] 에러 핸들링 체계
- [ ] 백엔드 API 연동
- [ ] 사용자 인증
- [ ] 실제 소셜 기능 (댓글, 팔로우)
- [ ] 레시피 검색
- [ ] 냉장고 재료 기반 추천

## 기술 스택

- **Framework**: Flutter 3.0+
- **언어**: Dart
- **상태 관리**: Provider
- **AI**: Google Gemini API
- **아키텍처**: MVC + Repository Pattern

## 라이센스

MIT License

## 개발자

Flutter MVC 프로토타입 프로젝트

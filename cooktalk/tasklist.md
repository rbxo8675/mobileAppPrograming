# 프로젝트 목표(1주 MVP)

* **핵심 경험**: 레시피 선택 → 단계별 안내(TTS, Text-to-Speech) → 음성 명령(ASR, Automatic Speech Recognition)으로 “다음/이전/다시/타이머 N분/일시정지/재개” → 단계 타이머 진행 → 완료.
* **우선순위**: 결과(온보딩 없이도 한 레시피를 끝까지 진행).
* **비우선**: 회원 관리·소셜·피드·리치 편집기·복잡한 NLU·개인화 → 전부 제외/후순위.

---

# 기술 스택(대중적 · 가볍게)

* **Flutter 3.x**, **Dart stable**
* **Firebase**: `firebase_core`, `firebase_auth`(anonymous), `cloud_firestore`, `firebase_analytics`
* **음성/오디오**: `speech_to_text`(ASR), `flutter_tts`(TTS)
* **권한/화면 유지**: `permission_handler`, `wakelock_plus`
* **상태관리**: `provider`(+ `ChangeNotifier`)  ← 가장 단순/대중적
* **기타**: `shared_preferences`(간단 로컬설정), `intl`(시간 포맷)

`pubspec.yaml` 핵심 의존성

```
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_analytics: ^11.0.0
  speech_to_text: ^6.6.0
  flutter_tts: ^3.8.0
  permission_handler: ^11.3.0
  wakelock_plus: ^1.2.5
  shared_preferences: ^2.2.2
  intl: ^0.19.0
```

---

# 화면/플로우(최소 3화면)

1. **레시피 목록(Home)**

* Firestore/로컬 JSON에서 3\~5개 샘플 레시피 목록.
* 탭하면 “조리 진행(Cooking Session)”로 진입.

2. **레시피 상세(간단)**

* 재료 리스트/단계 수만 표시. “시작” 버튼. (시간 안 되면 생략 가능)

3. **조리 진행(Cooking Session)** ← MVP의 핵심

* 상단: 레시피명, 현재 단계 x/n, 인분 버튼(초기 MVP에선 고정/비활성 가능)
* 본문: 현재 단계 텍스트(문장 짧게), 남은 시간(있으면), 큰 “마이크(Tap to Talk)” 버튼
* 하단: **빠른 명령(Quick Commands)** 버튼: \[다음]\[이전]\[다시]\[타이머 3분]\[일시정지]\[재개]
* **동작 규칙**:

  * 단계에 `base_time_sec` 있으면 “시작 시 자동 타이머 시작”.
  * TTS가 말할 땐 ASR 비활성(반이중: half-duplex). TTS 종료 콜백 후 **Tap to Talk**만 수신.
  * ASR 인식 → **규칙 기반 파서(Regex)** → Intent 매핑 → 액션 실행.

---

# 데이터 모델(가볍게)

* **로컬 JSON(1\~3개 레시피)** → 1일차 바로 결과 보기용. 3\~4일차에 Firestore로 이관.

```json
{
  "id": "r1",
  "title": "계란볶음밥",
  "servings_base": 2,
  "ingredients": [
    {"name":"밥", "qty":2, "unit":"공"},
    {"name":"계란", "qty":3, "unit":"개"}
  ],
  "steps": [
    {"order":1, "text":"팬을 달군 뒤 기름을 두른다.", "base_time_sec":30, "action_tag":"heat"},
    {"order":2, "text":"계란을 풀어 스크램블한다.", "base_time_sec":90, "action_tag":"stir"},
    {"order":3, "text":"밥을 넣고 고루 볶는다.", "base_time_sec":120, "action_tag":"stir"}
  ]
}
```

* **Firestore(후행)**

  * `recipes/{id}`: 위 필드 구조 동일
  * `users/{uid}`: 최소 `{ createdAt, lastRecipeId? }`
  * 인증: **Anonymous Auth**만 사용

---

# 음성 명령 스펙(가볍게, 규칙 기반 NLU)

* **지원 Intent**:

  * `NextStep`, `PrevStep`, `RepeatStep`,
  * `StartTimer(duration)` 예: “타이머 3분”, “1분 30초”,
  * `PauseTimer`, `ResumeTimer`
* **한국어 키워드 예시**

  * 다음/넘겨/다음 단계 → NextStep
  * 이전/뒤로/전 단계 → PrevStep
  * 다시/한번 더/다시 말해줘 → RepeatStep
  * 타이머/분/초 포함 + 숫자 → StartTimer
  * 멈춰/일시정지 → PauseTimer
  * 계속/재개 → ResumeTimer
* **Duration 파싱(Regex)**

  * `(\d+)\s*분` → minutes
  * `(\d+)\s*초` → seconds
  * 둘 다 있으면 합산.

---

# 아키텍처(심플)

```
lib/
  main.dart
  app.dart
  models/
    recipe.dart
    step.dart
  services/
    tts_service.dart
    asr_service.dart
    command_parser.dart
    timer_service.dart
    firestore_service.dart
    recipe_repository.dart   // Local JSON -> Firestore 전환 스위치
  providers/
    session_provider.dart    // ChangeNotifier (currentStep, timerState, etc.)
  screens/
    home_screen.dart
    recipe_detail_screen.dart
    cooking_session_screen.dart
  widgets/
    step_card.dart
    quick_commands.dart
  data/
    recipes.json             // 초기 로컬 샘플 데이터
```

* **반이중 제어(Half-duplex)**: `tts_service.speaking == true`면 ASR 시작 버튼 비활성. TTS 끝나면 마이크 버튼 활성.
* **타이머**: `Timer.periodic`로 1s 틱, `ChangeNotifier`로 UI 갱신. 단계 이동 시 현재 타이머 정리.

---

# 1주 일정(데이별 마일스톤)

* **D1**: 프로젝트/패키지 세팅, 로컬 JSON 로딩, Home/Session 기본 UI 뼈대
* **D2**: TTS 붙이고 단계 안내/다음·이전 버튼 동작, 타이머(자동 시작/일시정지/재개)
* **D3**: ASR 붙이고 Tap-to-Talk, 규칙 기반 파서, Intent → 액션 매핑
* **D4**: UX 다듬기(Quick Commands, Wakelock, 권한 안내), 에러/토스트 처리
* **D5**: Firebase 연결(Anonymous Auth, Firestore 읽기만), 레시피 소스 스위치(로컬↔원격)
* **D6**: QA 시나리오/버그픽스, Firebase Analytics 이벤트 심기
* **D7**: 버퍼(성능/크래시 핫픽스), 빌드/배포 아카이브

---

# 상세 태스크 리스트(주니어용 · 바로 쪼갠 작업)

체크박스는 그대로 티켓으로 복붙해 쓰세요. (각 태스크에 **완료조건(Acceptance Criteria)** 명시)

## 초기 설정 / 공통

* [ ] **\[TASK-001] Flutter 프로젝트 생성 & 패키지 추가**

  * `pubspec.yaml`에 위 의존성 추가, iOS/Android 권한 문구/설정(plist/manifest) 반영.
  * **완료조건**: `flutter run` 성공, 빌드 에러 없음.
* [ ] **\[TASK-002] Firebase 프로젝트 연결**

  * iOS/Android 앱 등록, `google-services` 설정, `firebase_core.initializeApp()` 호출.
  * **완료조건**: 런타임에서 Firebase 초기화 성공 로그 확인.
* [ ] **\[TASK-003] Anonymous Auth 적용**

  * 앱 스타트 시 `signInAnonymously()` 1회.
  * **완료조건**: `currentUser`가 null 아님.

## 데이터/모델

* [ ] **\[TASK-010] 레시피 모델 정의(models/recipe.dart)**

  * `Recipe`, `RecipeStep` 데이터클래스(From JSON).
  * **완료조건**: 로컬 JSON 파싱 테스트 통과.
* [ ] **\[TASK-011] 로컬 JSON 로더(services/recipe\_repository.dart)**

  * `getRecipes()`가 `data/recipes.json` 읽어 `List<Recipe>` 반환.
  * **완료조건**: Home에서 3개 샘플 표시.
* [ ] **\[TASK-012] Firestore 스키마 준비(Firestore 컬렉션 생성)**

  * `recipes/{id}` 문서에 샘플 3개 업로드.
  * **완료조건**: Firestore 콘솔에서 문서 확인 가능.
* [ ] **\[TASK-013] 레포지토리 스위치(로컬↔원격)**

  * 플래그로 소스 전환(초기: 로컬).
  * **완료조건**: 토글 시 Home 목록 소스 바뀜.

## UI/네비게이션

* [ ] **\[TASK-020] Home 화면(screens/home\_screen.dart)**

  * 카드 리스트(제목·단계수), 탭 → Session으로 이동.
  * **완료조건**: 더미 데이터로 탭 전환 OK.
* [ ] **\[TASK-021] Cooking Session 골격(screens/cooking\_session\_screen.dart)**

  * 상단 AppBar(제목, 단계 x/n), 본문(현재 단계 텍스트), 하단(마이크 버튼/퀵커맨드).
  * **완료조건**: 버튼 클릭 시 가짜 로직으로 다음/이전 이동.
* [ ] **\[TASK-022] Quick Commands 위젯(widgets/quick\_commands.dart)**

  * \[다음]\[이전]\[다시]\[타이머 3분]\[일시정지]\[재개] 버튼.
  * **완료조건**: 각 버튼이 Provider 액션 호출.

## 상태관리/세션

* [ ] **\[TASK-030] Session Provider(providers/session\_provider.dart)**

  * 상태: `currentStepIndex`, `currentTimerSec`, `isTimerRunning`, `speaking`, `listening`.
  * 액션: `nextStep()`, `prevStep()`, `repeatStep()`, `startTimer(sec)`, `pauseTimer()`, `resumeTimer()`.
  * **완료조건**: 단위테스트(각 액션 호출 시 상태 기대값).

## TTS(Text-to-Speech)

* [ ] **\[TASK-040] TTS 서비스(services/tts\_service.dart)**

  * `speak(text)`, `stop()`, 완료 콜백(onComplete). 한국어 기본.
  * **완료조건**: Session 첫 진입 시 현재 단계 읽어줌.
* [ ] **\[TASK-041] 반이중 제어(스피킹 중 마이크 비활성)**

  * `speaking=true`일 땐 마이크 버튼 disabled.
  * **완료조건**: 말이 끝나면 즉시 enabled.

## 타이머

* [ ] **\[TASK-050] 타이머 서비스(services/timer\_service.dart)**

  * `start(durationSec)`, `pause()`, `resume()`, `cancel()`, 1초 틱 콜백.
  * **완료조건**: 남은 시간이 UI에 1초 단위 반영.
* [ ] **\[TASK-051] 단계 진입 시 자동 타이머**

  * `base_time_sec`>0이면 자동 시작, 없으면 미시작.
  * **완료조건**: 단계 이동마다 타이머 재설정/취소 동작.

## ASR(Automatic Speech Recognition)

* [ ] **\[TASK-060] 권한 요청(마이크)**

  * `permission_handler`로 최초 1회 요청, 거부 시 안내 다이얼로그.
  * **완료조건**: 허용/거부 플로우 정상.
* [ ] **\[TASK-061] ASR 서비스(services/asr\_service.dart)**

  * `startListening()`, `stopListening()`, 인식 결과 스트림 제공.
  * **완료조건**: 테스트 버튼 누르면 문장 1회 인식.
* [ ] **\[TASK-062] Tap-to-Talk 마이크 버튼 연동**

  * 탭 시 `startListening()`, 5초 무음 or “종료” 키워드 시 `stopListening()`.
  * **완료조건**: 한 번 탭 → 말하기 → 결과 콜백 수신.

## 명령 파서/인텐트

* [ ] **\[TASK-070] 규칙 기반 파서(services/command\_parser.dart)**

  * 입력문자열 → Intent(enum) + 파라미터(durationSec?).
  * Regex: `(\d+)\s*분`, `(\d+)\s*초`. 키워드 매핑 테이블.
  * **완료조건**: 유닛 테스트(문장 10개 케이스) 통과.
* [ ] **\[TASK-071] Intent → 액션 매핑**

  * `NextStep/PrevStep/RepeatStep/StartTimer/PauseTimer/ResumeTimer`를 Session Provider 액션 호출로 연결.
  * **완료조건**: 실제 음성으로 “다음/이전/타이머 3분” 동작.

## UX 품질/안정화

* [ ] **\[TASK-080] Wakelock 적용**

  * Session 화면에서 화면 꺼지지 않도록 유지.
  * **완료조건**: 디바이스 화면 자동 꺼짐 미발생.
* [ ] **\[TASK-081] 에러 토스트/스낵바**

  * ASR 실패, 권한 거부, TTS 오류 시 사용자 메시지.
  * **완료조건**: 강제 실패 상황에서 안내 노출.
* [ ] **\[TASK-082] 한글 폰트/가독성 조정**

  * 본문 글자 크게(최소 18sp), 버튼 터치 타겟 48dp+.
  * **완료조건**: 디자인 점검 체크리스트 통과.

## Firebase 연동(후행이지만 1주 안에 가능)

* [ ] **\[TASK-090] Firestore 읽기 레포(services/firestore\_service.dart)**

  * `fetchRecipes()` → `List<Recipe>`.
  * **완료조건**: Home 데이터 소스 전환 스위치 동작.
* [ ] **\[TASK-091] Analytics 이벤트**

  * `session_start`, `step_next`, `timer_started`, `asr_intent` 등.
  * **완료조건**: DebugView에서 이벤트 수집 확인.

## 테스트/QA

* [ ] **\[TASK-100] 명령 파서 단위 테스트**

  * “타이머 3분”, “1분 30초”, “다시”, “이전 단계로” 등 10\~15케이스.
  * **완료조건**: 전부 통과(경계값 포함).
* [ ] **\[TASK-101] 수동 QA 시나리오**

  * 소음 없는 환경/약간 시끄러운 환경 각 5회 시나리오: “시작→TTS→다음→타이머 1분→일시정지→재개→완료”.
  * **완료조건**: 성공률 ≥ 80%.

---

# Definition of Done(완료 기준)

* 앱 실행 후 **설명 없이도** 샘플 레시피 1개를 **처음부터 끝까지** 음성/버튼 혼합으로 진행 가능.
* TTS/ASR가 서로 겹치지 않고(반이중), **Tap-to-Talk** 플로우가 명확.
* 단계 타이머가 시작/일시정지/재개/완료 룰대로 동작.
* 크래시/주요 에러 없이 10분 이상 연속 사용 가능.
* (선택) Firestore에서 레시피 읽기 스위치 가능, Analytics 이벤트 수집.

---

# 구현 팁(주니어 가이드)

* **상태 전이 표(최소)**

  * `speaking=true` ⇒ 마이크 버튼 `disabled`
  * `speaking=false` & `listening=false` ⇒ 마이크 `enabled`
  * 마이크 탭 ⇒ `listening=true` 시작, 결과/타임아웃 ⇒ `listening=false`
* **명령 우선순위**: `Pause/Resume`는 타이머 있을 때만 유효. 없으면 “타이머가 없습니다” TTS.
* **예외 처리**: 인식이 “타이머 …”지만 숫자 없음 ⇒ “몇 분으로 설정할까요?” TTS 후 종료(추가 청취는 MVP에선 미지원).


# 목표 정의

* “손 바쁘면 눈·입으로 조리” → 음성 기반(Voice UI) 레시피 진행과 단계별 타이머(Step Timer)로 조리 흐름을 끊지 않기.&#x20;

# 1) MVP 범위

* **핵심 플로우**: 로그인 → 메뉴(레시피) 선택 → 단계별 안내/타이머 → 완료.&#x20;
* **기능 세트**

  * 단계별 진행(Sequential Steps) + “다시/다음/반복” 음성 명령(ASR, NLU Intent).&#x20;
  * 한 단계당 타이머 설정 및 자동 시작/일시정지(Timer Orchestration).&#x20;
  * TTS로 다음 단계·남은 시간 읽어주기(Text-to-Speech).
  * 인분 수(servings) 바꾸면 재료 양 자동 환산(Scaling).&#x20;
* **후순위(차차)**: 스크랩, 후기/인증 피드, 사용자 레시피 추가/공개 범위, 유튜브에서 레시피 추출.   &#x20;

# 2) 화면/인터랙션 초안

* **조리 진행 화면**

  * 큰 글자 단계 카드(Next/Prev 대형 버튼은 보조), 실시간 음성 파형(ASR 상태), 남은 시간 표시.
  * 빠른 명령(Quick Commands): “다음/이전/다시 말해줘/타이머 3분/일시정지/재료 읽어줘/인분 2로”.
* **음성 UX(Voice UX)**

  * **Intents(의도)**: `NextStep`, `PrevStep`, `Repeat`, `StartTimer(duration)`, `PauseTimer`, `ReadIngredients`, `SetServings(n)`.
  * **피드백(TTS)**: “다음 단계: 양파 다지기. 2분 타이머 시작했습니다.”

# 3) 적응형 시간(Adaptive Timing)

* 문제의식: 사람마다 손질 속도가 다름.&#x20;
* **간단한 1차 해법(MVP)**: 단계 메타에 기본시간(base) 저장 → 사용자 프로필에 작업별 계수(skill multiplier: 손질/볶기/굽기) → 실제 타이머 = base × 계수.
* **학습(후속)**: 사용 로그로 단계 완료시간을 누적·이동평균해 계수 자동 업데이트(온디바이스 우선).

# 4) 데이터 모델(간단)

* `Recipe {id, title, servings_base, ingredients[{name, qty, unit}], steps[{order, text, base_time_sec, action_tag}]}`
* `UserProfile {id, skill_multiplier: {chop:1.0, fry:1.1,...}}`
* `Session {id, recipe_id, servings, step_index, timers[]}`
* 액션 태그(action\_tag: ‘chop’, ‘boil’, …)로 시간 보정과 TTS 톤 조절 가능.

# 5) 기술 스택 제안

* **클라이언트**: React Native(크로스플랫폼) 또는 Flutter.
* **ASR(음성 인식)**: iOS `SFSpeechRecognizer`, Android `SpeechRecognizer`(온디바이스), 품질 필요시 클라우드(STT) 옵션.
* **TTS**: iOS `AVSpeechSynthesizer`, Android TTS.
* **NLU**: 경량 규칙 기반(명령어 키워드 + duration 파싱)부터 시작 → 후에 LLM/Slot Filling.
* **권한/OS 설정**: 마이크 권한, 화면 항상 켜기, 백그라운드 오디오(TTS), 로컬 알림(타이머 종료).

# 6) 콘텐츠/저작권 전략(Content Licensing)

* 초기엔 **사용자 추가 레시피(UGC)** 중심 + 공개/비공개 옵션.&#x20;
* 외부 레시피는 링크/출처 명시와 요약 수준으로 표시(법률 검토 전 원문 복제 최소화).
* 유튜브 추출은 **R\&D 항목**(설명/자막 기반 단계 추출 스파이크).&#x20;

# 7) 성공 지표(Metrics)

* 첫 요리 세션 완료율, 단계당 TTS 재생 비율, 음성 명령 인식률(ASR WER), 한 레시피당 “중단 없이 진행” 비율, 타이머 오차 체감(피드백 설문).

# 8) 리스크 & 완화

* **잡음 환경에서 ASR 오인식** → 버튼 백업, 짧은 명령세트, TTS와 교대로 말하기(바로 뒤에 듣지 않기).
* **사용자별 속도 편차** → 적응형 시간 계수, 초반 캘리브레이션 단계(예: 30초 다지기 테스트).
* **콘텐츠 스케일** → UGC + 스크랩(후순위)로 초기 볼륨 확보.&#x20;

# 9) 다음 액션(2주 스프린트 가이드)

1. **프로토타입**: 1개 레시피 하드코딩 → 단계/타이머/TTS/기본 음성 명령 5종.
2. **사용 테스트(5명)**: 주방 소음 2가지 환경에서 성공/오류 로그.
3. **데이터 스키마/로컬 스토리지** 정리, 인분 스케일링 적용.
4. **후순위**: 레시피 추가·공개/비공개 토글, 후기/인증 피드(가볍게).&#x20;


# Phase 6: 레시피 탭 핵심 기능 (MVP 코어)

## 개요
레시피 탭(MyRecipesView)은 MVP의 핵심 기능으로, 모든 기능이 실제로 동작해야 합니다.

---

## 핵심 기능 목록

### 1. 내 레시피 관리
| 기능 | 상태 | 데이터 소스 |
|-----|------|------------|
| 레시피 목록 조회 | 실제 | Firestore |
| 레시피 추가 (수동) | 실제 | Firestore |
| 레시피 추가 (YouTube) | 실제 | YouTube API + Gemini |
| 레시피 수정 | 실제 | Firestore |
| 레시피 삭제 | 실제 | Firestore |

### 2. 저장된 레시피
| 기능 | 상태 | 데이터 소스 |
|-----|------|------------|
| 북마크된 레시피 목록 | 실제 | Firestore |
| 북마크 토글 | 실제 | Firestore |

### 3. 요리 가이드
| 기능 | 상태 | 데이터 소스 |
|-----|------|------------|
| 단계별 가이드 | 실제 | 레시피 데이터 |
| 타이머 기능 | 실제 | 로컬 |
| AI 요리 어시스턴트 | 실제 | Gemini API |
| 요리 완료 기록 | 실제 | Firestore |

---

## 데이터 흐름

### 레시피 목록 조회
```
MyRecipesView (내 레시피 탭)
  → RecipeController.loadMyRecipes()
  → RecipeRepository.getAllRecipes()
  → FirestoreRecipeRepository.getRecipesByAuthor(userId)
  → Firestore: users/{userId}/recipes
```

### 저장된 레시피 조회
```
MyRecipesView (저장됨 탭)
  → RecipeController.loadSavedRecipes()
  → RecipeRepository.getBookmarkedRecipes()
  → FirestoreRecipeRepository.getBookmarkedRecipes(userId)
  → Firestore: bookmarks/{userId}/recipes
```

---

## 현재 구현 확인

### 1. MyRecipesView (`lib/views/my_recipes_view.dart`)

```dart
// SegmentedButton으로 탭 전환
SegmentedButton<RecipesTab>(
  segments: const [
    ButtonSegment(value: RecipesTab.myRecipes, label: Text('내 레시피')),
    ButtonSegment(value: RecipesTab.saved, label: Text('저장됨')),
  ],
  selected: {tab},
  onSelectionChanged: (s) => setState(() => tab = s.first),
)

// 내 레시피 표시
if (tab == RecipesTab.myRecipes) {
  if (rc.loadingMyRecipes) {
    return SkeletonLoader();
  } else if (rc.myRecipes.isEmpty) {
    return EmptyState(
      message: '작성한 레시피가 없습니다',
      actionLabel: '+ 레시피 추가하기',
      onAction: () => showAddRecipeSheet(),
    );
  } else {
    return GridView/ListView of recipes;
  }
}
```

### 2. 레시피 추가 (`lib/views/add_recipe_sheet.dart`)

```dart
// FAB 메뉴에서 호출
showFabMenu(
  context,
  onAddManual: () => context.push(const RecipeFormView()),
  onExtractYoutube: () => context.push(const YoutubeExtractView()),
);
```

### 3. 요리 가이드 (`lib/views/cooking_guide_view.dart`)

```dart
// 레시피 상세에서 "요리 시작" 버튼 클릭 시
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CookingGuideView(recipe: recipe),
  ),
);
```

---

## 레시피 CRUD 플로우

### Create (생성)
```
1. FAB 버튼 클릭
2. "직접 입력" 또는 "YouTube에서 추출" 선택
3-a. 직접 입력: RecipeFormView → addManualRecipe()
3-b. YouTube: YoutubeExtractView → importFromYouTube()
4. Firestore에 저장
5. myRecipes 목록 갱신
```

### Read (조회)
```
1. 레시피 탭 접속
2. RecipeController.loadMyRecipes() 호출
3. Firestore에서 사용자 레시피 조회
4. GridView/ListView로 표시
```

### Update (수정)
```
1. 레시피 카드에서 수정 버튼 클릭
2. RecipeFormView(recipe: existing) 열기
3. 수정 후 저장
4. updateRecipe() 호출
5. Firestore 업데이트
```

### Delete (삭제)
```
1. 레시피 카드에서 삭제 버튼 클릭
2. 확인 다이얼로그
3. deleteRecipe(id) 호출
4. Firestore에서 삭제
5. 목록에서 제거
```

---

## 요리 가이드 플로우

```
RecipeDetailView
  ↓ "요리 시작" 버튼
CookingGuideView
  ├─ 단계별 진행 (steps)
  ├─ 타이머 기능 (timerMinutes)
  ├─ AI 어시스턴트 (Gemini)
  └─ 음성 제어 (VoiceOrchestrator)
  ↓ 마지막 단계 완료
markCompleted(recipe)
  ↓
completedCount 증가
  ↓
프로필 탭 통계 반영
```

---

## 체크리스트

### 필수 기능 확인
- [ ] 레시피 목록 조회 (Firestore)
- [ ] 레시피 수동 추가 (RecipeFormView)
- [ ] 레시피 YouTube 추출 (YoutubeExtractView + Gemini)
- [ ] 레시피 수정
- [ ] 레시피 삭제
- [ ] 북마크 목록 조회
- [ ] 북마크 토글
- [ ] 요리 가이드 시작
- [ ] 단계별 진행
- [ ] 타이머 동작
- [ ] 요리 완료 기록

### 연동 확인
- [ ] AI 어시스턴트 (Gemini API)
- [ ] 음성 인식 (VoiceOrchestrator)
- [ ] TTS (TextToSpeech)

---

## 테스트 시나리오

### 시나리오 1: 레시피 추가
1. 레시피 탭 이동
2. FAB 버튼 클릭
3. "직접 입력" 선택
4. 제목, 재료, 단계 입력
5. 저장 버튼 클릭
6. 목록에 새 레시피 표시 확인

### 시나리오 2: YouTube 추출
1. FAB → "YouTube에서 추출"
2. YouTube URL 입력
3. 추출 버튼 클릭
4. 레시피 정보 자동 채움 확인
5. 저장
6. 목록에 추가 확인

### 시나리오 3: 요리 진행
1. 레시피 카드 클릭 → 상세 페이지
2. "요리 시작" 버튼 클릭
3. 단계별 진행
4. 타이머 사용
5. AI 어시스턴트 질문
6. 마지막 단계 완료
7. 프로필 탭 → "완료한 요리" 개수 증가 확인

### 시나리오 4: 북마크
1. 레시피 상세에서 북마크 버튼 클릭
2. 레시피 탭 → "저장됨" 탭 이동
3. 북마크한 레시피 표시 확인
4. 프로필 탭 → "스크랩한 레시피" 개수 확인

---

## 에러 핸들링

```dart
// 네트워크 에러
try {
  await recipeController.loadMyRecipes();
} catch (e) {
  showErrorSnackBar('레시피를 불러올 수 없습니다');
}

// Firestore 권한 에러
// firestore.rules 확인 필요

// Gemini API 에러
// API 키 및 할당량 확인
```

---

## MVP 완료 조건

1. **레시피 CRUD**: 모든 작업이 Firestore와 동기화
2. **북마크**: 저장/해제가 실시간 반영
3. **요리 가이드**: 단계 진행 및 완료 기록
4. **프로필 연동**: 완료 개수, 스크랩 개수 실시간 반영

---

## 최종 앱 구조

```
CookTalk MVP
├── 홈 탭 (목업 데이터)
│   └── 오늘의 추천 5개
├── 인기 탭 (목업 데이터)
│   └── 트렌딩 레시피 6개
├── 피드 탭 (목업 데이터)
│   └── 소셜 피드 4개
├── 레시피 탭 (실제 기능) ⭐ MVP 코어
│   ├── 내 레시피 (Firestore)
│   ├── 저장됨 (Firestore)
│   └── 요리 가이드 (실제)
└── 프로필 탭 (하이브리드)
    ├── 완료한 요리 (실제)
    ├── 스크랩한 레시피 (실제)
    ├── 좋아하는 레시피 (목업)
    ├── 팔로잉 (목업)
    └── 설정 (실제)
```

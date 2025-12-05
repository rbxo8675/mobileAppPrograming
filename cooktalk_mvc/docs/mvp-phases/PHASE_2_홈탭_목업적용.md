# Phase 2: 홈(탐색) 탭 목업 데이터 적용

## 개요
홈 탭(ExploreView)에서 실제 API 대신 목업 데이터를 사용하도록 변경합니다.

---

## 현재 상태 분석

### 현재 데이터 흐름
```
ExploreView
  → RecipeController.loadExplore()
  → RecipeRepository.getExploreRecipes()
  → RecipeService.fetchExplore()
  → 실제 API 호출
```

### 변경 후 데이터 흐름
```
ExploreView
  → RecipeController.loadExplore()
  → RecipeRepository.getExploreRecipes()
  → MockRecipeService.fetchExploreRecipes()
  → MockData.exploreRecipes
```

---

## 구현 작업

### 1. RecipeService 수정 (`lib/data/services/recipe_service.dart`)

```dart
import '../mock/mock_data.dart';
import '../../models/recipe.dart';

class RecipeService {
  // MVP 모드 플래그 - true면 목업 데이터 사용
  static const bool _useMockData = true;

  Future<List<Recipe>> fetchExplore() async {
    if (_useMockData) {
      // 네트워크 지연 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 300));
      return _convertMockToRecipes(MockData.exploreRecipes);
    }

    // 실제 API 호출 (MVP 이후 활성화)
    // return await _fetchFromApi();
    return [];
  }

  List<Recipe> _convertMockToRecipes(List<Map<String, dynamic>> mockList) {
    return mockList.map((data) {
      return Recipe.fromStringSteps(
        id: data['id'] as String,
        title: data['title'] as String,
        imagePath: data['imagePath'] as String?,
        durationMinutes: data['durationMinutes'] as int? ?? 0,
        difficulty: data['difficulty'] as String?,
        description: data['description'] as String?,
        ingredients: (data['ingredients'] as List?)?.cast<String>() ?? [],
        stringSteps: (data['steps'] as List?)?.cast<String>() ?? [],
        tags: (data['tags'] as List?)?.cast<String>() ?? [],
        rating: (data['rating'] as num?)?.toDouble(),
        likeCount: data['likeCount'] as int? ?? 0,
        bookmarkCount: data['bookmarkCount'] as int? ?? 0,
      );
    }).toList();
  }
}
```

### 2. ExploreView 확인 사항 (`lib/views/explore_view.dart`)

현재 ExploreView는 이미 RecipeController를 통해 데이터를 받고 있으므로 뷰 수정은 불필요합니다.

```dart
// 기존 코드 유지 - 변경 없음
Consumer<RecipeController>(
  builder: (context, rc, child) {
    if (rc.loadingExplore) {
      return const CircularProgressIndicator();
    }

    if (rc.explore.isEmpty) {
      return const EmptyState(message: '추천 레시피가 없습니다');
    }

    // 목업 데이터가 자동으로 표시됨
    return ListView.builder(...);
  },
)
```

---

## 표시되는 목업 데이터

| 레시피명 | 조리시간 | 난이도 | 태그 |
|---------|---------|--------|------|
| 김치볶음밥 | 15분 | 쉬움 | 한식, 간단, 볶음밥 |
| 크림 파스타 | 25분 | 보통 | 양식, 파스타, 크림 |
| 된장찌개 | 30분 | 쉬움 | 한식, 찌개, 집밥 |
| 계란말이 | 10분 | 쉬움 | 한식, 반찬, 간단 |
| 불고기 | 40분 | 보통 | 한식, 고기, 메인 |

---

## 체크리스트

- [ ] RecipeService에 목업 데이터 분기 추가
- [ ] MockData import 추가
- [ ] 네트워크 지연 시뮬레이션 추가
- [ ] 앱 실행 후 홈 탭 목업 데이터 표시 확인

---

## 테스트 시나리오

1. 앱 실행 → 홈 탭 확인
2. 5개의 목업 레시피가 표시되는지 확인
3. 더보기 버튼 동작 확인
4. Pull-to-refresh 동작 확인
5. 레시피 카드 클릭 → 상세 페이지 이동 확인

---

## 다음 단계
Phase 3에서 인기(트렌딩) 탭에 목업 데이터를 적용합니다.

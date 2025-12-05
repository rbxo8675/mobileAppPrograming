# Phase 1: 목업 데이터 인프라 구축

## 개요
MVP 구현을 위한 목업 데이터 서비스 및 상수 파일을 구축합니다.

---

## 목표
- 홈, 인기, 피드 탭에서 사용할 통합 목업 데이터 관리 시스템 구축
- 실제 API 호출 없이 앱이 정상 작동하도록 목업 데이터 제공
- 향후 실제 데이터로 쉽게 전환 가능한 구조 설계

---

## 구현 파일

### 1. `lib/data/mock/mock_data.dart` (신규 생성)

```dart
/// MVP용 목업 데이터 저장소
/// 홈, 인기, 피드 탭에서 사용하는 정적 데이터를 관리합니다.
class MockData {
  MockData._();

  /// 홈(탐색) 탭 - 오늘의 추천 레시피
  static final List<Map<String, dynamic>> exploreRecipes = [
    {
      'id': 'mock_1',
      'title': '김치볶음밥',
      'imagePath': 'https://images.unsplash.com/photo-1516685018646-549198525c1b?w=800',
      'durationMinutes': 15,
      'difficulty': '쉬움',
      'description': '간단하고 맛있는 한국식 볶음밥',
      'ingredients': ['밥 2공기', '김치 1컵', '계란 2개', '참기름', '깨'],
      'steps': ['김치를 잘게 썬다', '팬에 기름을 두르고 김치를 볶는다', '밥을 넣고 함께 볶는다', '계란 프라이를 올린다'],
      'tags': ['한식', '간단', '볶음밥'],
      'rating': 4.5,
      'likeCount': 128,
      'bookmarkCount': 45,
    },
    {
      'id': 'mock_2',
      'title': '크림 파스타',
      'imagePath': 'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=800',
      'durationMinutes': 25,
      'difficulty': '보통',
      'description': '부드러운 크림소스 파스타',
      'ingredients': ['파스타 200g', '생크림 200ml', '베이컨 100g', '마늘', '파마산 치즈'],
      'steps': ['파스타를 삶는다', '베이컨을 볶는다', '생크림을 넣고 끓인다', '파스타와 섞는다'],
      'tags': ['양식', '파스타', '크림'],
      'rating': 4.7,
      'likeCount': 256,
      'bookmarkCount': 89,
    },
    {
      'id': 'mock_3',
      'title': '된장찌개',
      'imagePath': 'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?w=800',
      'durationMinutes': 30,
      'difficulty': '쉬움',
      'description': '구수한 집밥 된장찌개',
      'ingredients': ['된장 2큰술', '두부 1/2모', '감자 1개', '호박 1/2개', '대파'],
      'steps': ['육수를 끓인다', '된장을 풀어준다', '채소를 넣고 끓인다', '두부를 넣고 마무리'],
      'tags': ['한식', '찌개', '집밥'],
      'rating': 4.8,
      'likeCount': 342,
      'bookmarkCount': 156,
    },
    {
      'id': 'mock_4',
      'title': '계란말이',
      'imagePath': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800',
      'durationMinutes': 10,
      'difficulty': '쉬움',
      'description': '부드러운 계란말이',
      'ingredients': ['계란 3개', '당근', '대파', '소금', '설탕'],
      'steps': ['계란을 풀어준다', '채소를 잘게 썬다', '팬에서 말아가며 굽는다'],
      'tags': ['한식', '반찬', '간단'],
      'rating': 4.3,
      'likeCount': 98,
      'bookmarkCount': 34,
    },
    {
      'id': 'mock_5',
      'title': '불고기',
      'imagePath': 'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=800',
      'durationMinutes': 40,
      'difficulty': '보통',
      'description': '달콤한 불고기',
      'ingredients': ['소고기 300g', '배 1/4개', '간장', '설탕', '마늘'],
      'steps': ['고기를 양념에 재운다', '30분 숙성', '팬에 구워낸다'],
      'tags': ['한식', '고기', '메인'],
      'rating': 4.9,
      'likeCount': 512,
      'bookmarkCount': 234,
    },
  ];

  /// 인기 탭 - 트렌딩 레시피 (viewCount 기준 정렬)
  static final List<Map<String, dynamic>> trendingRecipes = [
    {
      'id': 'trend_1',
      'title': '마라탕',
      'imagePath': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800',
      'durationMinutes': 35,
      'difficulty': '보통',
      'description': '얼얼한 마라탕',
      'viewCount': 15420,
      'likeCount': 892,
      'rating': 4.6,
      'tags': ['중식', '마라', '매운맛'],
    },
    {
      'id': 'trend_2',
      'title': '떡볶이',
      'imagePath': 'https://images.unsplash.com/photo-1635363638580-c2809d049eee?w=800',
      'durationMinutes': 20,
      'difficulty': '쉬움',
      'description': '매콤달콤 떡볶이',
      'viewCount': 12350,
      'likeCount': 756,
      'rating': 4.8,
      'tags': ['한식', '분식', '매운맛'],
    },
    {
      'id': 'trend_3',
      'title': '치킨 샐러드',
      'imagePath': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
      'durationMinutes': 15,
      'difficulty': '쉬움',
      'description': '건강한 치킨 샐러드',
      'viewCount': 9870,
      'likeCount': 543,
      'rating': 4.4,
      'tags': ['양식', '샐러드', '다이어트'],
    },
    {
      'id': 'trend_4',
      'title': '참치김밥',
      'imagePath': 'https://images.unsplash.com/photo-1553163147-622ab57be1c7?w=800',
      'durationMinutes': 25,
      'difficulty': '보통',
      'description': '참치 듬뿍 김밥',
      'viewCount': 8920,
      'likeCount': 421,
      'rating': 4.5,
      'tags': ['한식', '분식', '도시락'],
    },
    {
      'id': 'trend_5',
      'title': '카레라이스',
      'imagePath': 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=800',
      'durationMinutes': 45,
      'difficulty': '쉬움',
      'description': '일본식 카레라이스',
      'viewCount': 7650,
      'likeCount': 389,
      'rating': 4.7,
      'tags': ['일식', '카레', '메인'],
    },
    {
      'id': 'trend_6',
      'title': '닭갈비',
      'imagePath': 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800',
      'durationMinutes': 35,
      'difficulty': '보통',
      'description': '춘천식 닭갈비',
      'viewCount': 6540,
      'likeCount': 298,
      'rating': 4.6,
      'tags': ['한식', '고기', '매운맛'],
    },
  ];

  /// 피드 탭 - 소셜 피드 게시물
  static final List<Map<String, dynamic>> feedPosts = [
    {
      'id': 'feed_1',
      'userId': 'user_1',
      'userName': '요리하는 민지',
      'userImage': null,
      'recipeTitle': '오늘의 김치찌개',
      'recipeImage': 'https://images.unsplash.com/photo-1516685018646-549198525c1b?w=800',
      'description': '오랜만에 만든 김치찌개! 돼지고기 듬뿍 넣었어요',
      'likes': 156,
      'comments': 23,
      'timeAgo': '2시간 전',
      'tags': ['오늘의요리', '한식', '집밥'],
      'isFollowing': false,
    },
    {
      'id': 'feed_2',
      'userId': 'user_2',
      'userName': '파스타 러버',
      'userImage': null,
      'recipeTitle': '까르보나라',
      'recipeImage': 'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=800',
      'description': '진짜 이탈리안 까르보나라 도전! 생크림 없이 만들었어요',
      'likes': 289,
      'comments': 45,
      'timeAgo': '4시간 전',
      'tags': ['파스타', '이탈리안', '양식'],
      'isFollowing': true,
    },
    {
      'id': 'feed_3',
      'userId': 'user_3',
      'userName': '베이킹 초보',
      'userImage': null,
      'recipeTitle': '바나나 빵',
      'recipeImage': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=800',
      'description': '첫 베이킹 도전! 생각보다 쉬웠어요',
      'likes': 98,
      'comments': 12,
      'timeAgo': '6시간 전',
      'tags': ['베이킹', '빵', '디저트'],
      'isFollowing': false,
    },
    {
      'id': 'feed_4',
      'userId': 'user_4',
      'userName': '건강식단 지수',
      'userImage': null,
      'recipeTitle': '그릭 샐러드',
      'recipeImage': 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800',
      'description': '다이어트 중인데 맛있게 먹을 수 있어요!',
      'likes': 234,
      'comments': 31,
      'timeAgo': '8시간 전',
      'tags': ['샐러드', '다이어트', '건강식'],
      'isFollowing': true,
    },
  ];

  /// 프로필 - 팔로잉 목업 데이터
  static const int mockFollowingCount = 12;
  static const int mockFollowerCount = 45;

  /// 프로필 - 좋아하는 레시피 목업 개수
  static const int mockLikedRecipeCount = 28;
}
```

### 2. `lib/data/services/mock_recipe_service.dart` (신규 생성)

```dart
import '../../models/recipe.dart';
import '../mock/mock_data.dart';

/// 목업 레시피 데이터를 제공하는 서비스
class MockRecipeService {
  /// 탐색(홈) 레시피 목록 반환
  Future<List<Recipe>> fetchExploreRecipes() async {
    // 네트워크 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));

    return MockData.exploreRecipes.map((data) => _mapToRecipe(data)).toList();
  }

  /// 인기(트렌딩) 레시피 목록 반환
  Future<List<Recipe>> fetchTrendingRecipes() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return MockData.trendingRecipes.map((data) => _mapToRecipe(data)).toList();
  }

  Recipe _mapToRecipe(Map<String, dynamic> data) {
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
      viewCount: data['viewCount'] as int? ?? 0,
    );
  }
}
```

---

## 체크리스트

- [ ] `lib/data/mock/` 디렉토리 생성
- [ ] `mock_data.dart` 파일 생성 및 목업 데이터 정의
- [ ] `mock_recipe_service.dart` 파일 생성
- [ ] Recipe 모델에서 목업 데이터 호환성 확인

---

## 다음 단계
Phase 2에서 홈(탐색) 탭에 목업 데이터를 적용합니다.

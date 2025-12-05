import '../../models/recipe.dart';
import '../mock/mock_data.dart';

class RecipeService {
  // MVP 모드 플래그 - true면 목업 데이터 사용
  static const bool _useMockData = true;

  Future<List<Recipe>> fetchExplore() async {
    // 네트워크 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));

    if (_useMockData) {
      return _convertMockToRecipes(MockData.exploreRecipes);
    }

    // 실제 API 호출 (MVP 이후 활성화)
    return [];
  }

  Future<List<Recipe>> fetchTrending() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_useMockData) {
      return _convertMockToRecipes(MockData.trendingRecipes);
    }

    // 실제 API 호출 (MVP 이후 활성화)
    return [];
  }

  /// 목업 데이터를 Recipe 객체 리스트로 변환
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
        viewCount: data['viewCount'] as int? ?? 0,
      );
    }).toList();
  }
}

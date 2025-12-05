import '../../models/recipe.dart';

class RecipeService {
  Future<List<Recipe>> fetchExplore() async {
    // Mock data removed
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<List<Recipe>> fetchTrending() async {
    // Mock data removed
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }
}

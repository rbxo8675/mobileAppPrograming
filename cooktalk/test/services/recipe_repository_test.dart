import 'package:cooktalk/services/recipe_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecipeRepository recipeRepository;

  setUp(() {
    recipeRepository = RecipeRepository();
  });

  test('getRecipes returns a list of recipes from local JSON', () async {
    final recipes = await recipeRepository.getRecipes();

    expect(recipes.length, 3);
    expect(recipes[0].title, '계란볶음밥');
    expect(recipes[1].title, '김치찌개');
    expect(recipes[2].title, '간단 토스트');
  });
}
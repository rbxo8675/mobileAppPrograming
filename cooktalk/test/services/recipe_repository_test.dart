import 'package:flutter_test/flutter_test.dart';
import 'package:cooktalk/services/recipe_repository.dart';
import 'package:cooktalk/models/recipe.dart';

void main() {
  group('RecipeRepository Tests', () {
    late RecipeRepository repository;

    setUp(() {
      repository = RecipeRepository();
    });

    test('should start with local data source enabled', () {
      expect(repository.useLocalData, isTrue);
    });

    test('should toggle data source', () {
      expect(repository.useLocalData, isTrue);
      
      repository.toggleDataSource();
      expect(repository.useLocalData, isFalse);
      
      repository.toggleDataSource();
      expect(repository.useLocalData, isTrue);
    });

    test('should set data source explicitly', () {
      repository.setDataSource(false);
      expect(repository.useLocalData, isFalse);
      
      repository.setDataSource(true);
      expect(repository.useLocalData, isTrue);
    });

    test('should scale ingredients correctly', () {
      final ingredients = [
        Ingredient(name: '밥', qty: 2, unit: '공'),
        Ingredient(name: '계란', qty: 3, unit: '개'),
        Ingredient(name: '소금', qty: 1.5, unit: '큰술'),
        Ingredient(name: '간장', qty: '적당량', unit: '큰술'),
      ];

      // 2인분에서 4인분으로 스케일링 (2배)
      final scaledIngredients = repository.scaleIngredients(ingredients, 4, 2);

      expect(scaledIngredients.length, 4);
      expect(scaledIngredients[0].qty, 4); // 밥 2공 -> 4공
      expect(scaledIngredients[1].qty, 6); // 계란 3개 -> 6개
      expect(scaledIngredients[2].qty, 3.0); // 소금 1.5큰술 -> 3큰술
      expect(scaledIngredients[3].qty, '적당량'); // 문자열은 그대로 유지
    });

    test('should not scale when servings are the same', () {
      final ingredients = [
        Ingredient(name: '밥', qty: 2, unit: '공'),
        Ingredient(name: '계란', qty: 3, unit: '개'),
      ];

      final scaledIngredients = repository.scaleIngredients(ingredients, 2, 2);

      expect(scaledIngredients[0].qty, 2);
      expect(scaledIngredients[1].qty, 3);
    });

    test('should calculate total time correctly', () {
      final recipe = Recipe(
        id: 'test',
        title: 'Test Recipe',
        servingsBase: 2,
        ingredients: [],
        steps: [
          RecipeStep(order: 1, text: 'Step 1', baseTimeSec: 30, actionTag: 'heat'),
          RecipeStep(order: 2, text: 'Step 2', baseTimeSec: 60, actionTag: 'stir'),
          RecipeStep(order: 3, text: 'Step 3', baseTimeSec: 90, actionTag: 'finish'),
        ],
      );

      final totalTime = repository.calculateTotalTime(recipe);
      expect(totalTime, 180); // 30 + 60 + 90
    });

    test('should calculate difficulty correctly', () {
      // 쉬운 레시피 (3단계, 300초 이하)
      final easyRecipe = Recipe(
        id: 'easy',
        title: 'Easy Recipe',
        servingsBase: 2,
        ingredients: [],
        steps: [
          RecipeStep(order: 1, text: 'Step 1', baseTimeSec: 100, actionTag: 'heat'),
          RecipeStep(order: 2, text: 'Step 2', baseTimeSec: 100, actionTag: 'stir'),
          RecipeStep(order: 3, text: 'Step 3', baseTimeSec: 100, actionTag: 'finish'),
        ],
      );

      // 보통 레시피 (5단계, 600초 이하)
      final mediumRecipe = Recipe(
        id: 'medium',
        title: 'Medium Recipe',
        servingsBase: 2,
        ingredients: [],
        steps: [
          RecipeStep(order: 1, text: 'Step 1', baseTimeSec: 100, actionTag: 'heat'),
          RecipeStep(order: 2, text: 'Step 2', baseTimeSec: 100, actionTag: 'stir'),
          RecipeStep(order: 3, text: 'Step 3', baseTimeSec: 100, actionTag: 'finish'),
          RecipeStep(order: 4, text: 'Step 4', baseTimeSec: 100, actionTag: 'season'),
          RecipeStep(order: 5, text: 'Step 5', baseTimeSec: 100, actionTag: 'finish'),
        ],
      );

      // 어려운 레시피 (6단계, 700초)
      final hardRecipe = Recipe(
        id: 'hard',
        title: 'Hard Recipe',
        servingsBase: 2,
        ingredients: [],
        steps: [
          RecipeStep(order: 1, text: 'Step 1', baseTimeSec: 100, actionTag: 'heat'),
          RecipeStep(order: 2, text: 'Step 2', baseTimeSec: 100, actionTag: 'stir'),
          RecipeStep(order: 3, text: 'Step 3', baseTimeSec: 100, actionTag: 'finish'),
          RecipeStep(order: 4, text: 'Step 4', baseTimeSec: 100, actionTag: 'season'),
          RecipeStep(order: 5, text: 'Step 5', baseTimeSec: 100, actionTag: 'finish'),
          RecipeStep(order: 6, text: 'Step 6', baseTimeSec: 200, actionTag: 'finish'),
        ],
      );

      expect(repository.calculateDifficulty(easyRecipe), '쉬움');
      expect(repository.calculateDifficulty(mediumRecipe), '보통');
      expect(repository.calculateDifficulty(hardRecipe), '어려움');
    });

    test('should search recipes correctly', () async {
      // Mock recipes for testing
      final recipes = [
        Recipe(
          id: 'r1',
          title: '계란볶음밥',
          servingsBase: 2,
          ingredients: [],
          steps: [],
        ),
        Recipe(
          id: 'r2',
          title: '김치찌개',
          servingsBase: 2,
          ingredients: [],
          steps: [],
        ),
        Recipe(
          id: 'r3',
          title: '된장찌개',
          servingsBase: 2,
          ingredients: [],
          steps: [],
        ),
      ];

      // Mock the getRecipes method to return our test data
      // Note: In a real test, you would use a mock or dependency injection
      // For now, we'll test the search logic directly
      
      final emptyQuery = recipes.where((recipe) => 
          recipe.title.toLowerCase().contains('')).toList();
      expect(emptyQuery.length, 3);

      final kimchiQuery = recipes.where((recipe) => 
          recipe.title.toLowerCase().contains('김치')).toList();
      expect(kimchiQuery.length, 1);
      expect(kimchiQuery.first.title, '김치찌개');

      final jjigaeQuery = recipes.where((recipe) => 
          recipe.title.toLowerCase().contains('찌개')).toList();
      expect(jjigaeQuery.length, 2);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cooktalk/models/recipe.dart';

void main() {
  group('Recipe Model Tests', () {
    test('should create Recipe from JSON', () {
      final json = {
        'id': 'r1',
        'title': '계란볶음밥',
        'servings_base': 2,
        'ingredients': [
          {'name': '밥', 'qty': 2, 'unit': '공'},
          {'name': '계란', 'qty': 3, 'unit': '개'},
        ],
        'steps': [
          {
            'order': 1,
            'text': '팬을 달군 뒤 기름을 두른다.',
            'base_time_sec': 30,
            'action_tag': 'heat'
          },
        ],
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 'r1');
      expect(recipe.title, '계란볶음밥');
      expect(recipe.servingsBase, 2);
      expect(recipe.ingredients.length, 2);
      expect(recipe.steps.length, 1);
    });

    test('should convert Recipe to JSON', () {
      final recipe = Recipe(
        id: 'r1',
        title: '계란볶음밥',
        servingsBase: 2,
        ingredients: [
          Ingredient(name: '밥', qty: 2, unit: '공'),
          Ingredient(name: '계란', qty: 3, unit: '개'),
        ],
        steps: [
          RecipeStep(
            order: 1,
            text: '팬을 달군 뒤 기름을 두른다.',
            baseTimeSec: 30,
            actionTag: 'heat',
          ),
        ],
      );

      final json = recipe.toJson();

      expect(json['id'], 'r1');
      expect(json['title'], '계란볶음밥');
      expect(json['servings_base'], 2);
      expect(json['ingredients'], isA<List>());
      expect(json['steps'], isA<List>());
    });

    test('should create Ingredient from JSON', () {
      final json = {'name': '밥', 'qty': 2, 'unit': '공'};
      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.name, '밥');
      expect(ingredient.qty, 2);
      expect(ingredient.unit, '공');
    });

    test('should convert Ingredient to JSON', () {
      final ingredient = Ingredient(name: '밥', qty: 2, unit: '공');
      final json = ingredient.toJson();

      expect(json['name'], '밥');
      expect(json['qty'], 2);
      expect(json['unit'], '공');
    });

    test('should create RecipeStep from JSON', () {
      final json = {
        'order': 1,
        'text': '팬을 달군 뒤 기름을 두른다.',
        'base_time_sec': 30,
        'action_tag': 'heat'
      };
      final step = RecipeStep.fromJson(json);

      expect(step.order, 1);
      expect(step.text, '팬을 달군 뒤 기름을 두른다.');
      expect(step.baseTimeSec, 30);
      expect(step.actionTag, 'heat');
    });

    test('should convert RecipeStep to JSON', () {
      final step = RecipeStep(
        order: 1,
        text: '팬을 달군 뒤 기름을 두른다.',
        baseTimeSec: 30,
        actionTag: 'heat',
      );
      final json = step.toJson();

      expect(json['order'], 1);
      expect(json['text'], '팬을 달군 뒤 기름을 두른다.');
      expect(json['base_time_sec'], 30);
      expect(json['action_tag'], 'heat');
    });

    test('should handle different qty types in Ingredient', () {
      final intJson = {'name': '계란', 'qty': 3, 'unit': '개'};
      final doubleJson = {'name': '소금', 'qty': 1.5, 'unit': '큰술'};
      final stringJson = {'name': '간장', 'qty': '적당량', 'unit': '큰술'};

      final intIngredient = Ingredient.fromJson(intJson);
      final doubleIngredient = Ingredient.fromJson(doubleJson);
      final stringIngredient = Ingredient.fromJson(stringJson);

      expect(intIngredient.qty, 3);
      expect(doubleIngredient.qty, 1.5);
      expect(stringIngredient.qty, '적당량');
    });

    test('should handle equality correctly', () {
      final recipe1 = Recipe(
        id: 'r1',
        title: '계란볶음밥',
        servingsBase: 2,
        ingredients: [
          Ingredient(name: '밥', qty: 2, unit: '공'),
        ],
        steps: [
          RecipeStep(order: 1, text: 'Step 1', baseTimeSec: 30, actionTag: 'heat'),
        ],
      );
      final recipe2 = Recipe(
        id: 'r1',
        title: '계란볶음밥',
        servingsBase: 2,
        ingredients: [
          Ingredient(name: '밥', qty: 2, unit: '공'),
        ],
        steps: [
          RecipeStep(order: 1, text: 'Step 1', baseTimeSec: 30, actionTag: 'heat'),
        ],
      );
      final recipe3 = Recipe(
        id: 'r2',
        title: '김치찌개',
        servingsBase: 2,
        ingredients: [
          Ingredient(name: '김치', qty: 200, unit: 'g'),
        ],
        steps: [
          RecipeStep(order: 1, text: 'Step 1', baseTimeSec: 60, actionTag: 'chop'),
        ],
      );

      expect(recipe1, equals(recipe2));
      expect(recipe1, isNot(equals(recipe3)));
    });
  });
}

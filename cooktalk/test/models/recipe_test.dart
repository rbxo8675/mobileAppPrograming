import 'dart:convert';
import 'package:cooktalk/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Recipe.fromJson parses a valid JSON string', () {
    const jsonString = '''
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
    ''';

    final recipe = Recipe.fromJson(json.decode(jsonString) as Map<String, dynamic>);

    expect(recipe.id, 'r1');
    expect(recipe.title, '계란볶음밥');
    expect(recipe.servingsBase, 2);
    expect(recipe.ingredients.length, 2);
    expect(recipe.ingredients[0].name, '밥');
    expect(recipe.ingredients[0].qty, 2);
    expect(recipe.ingredients[0].unit, '공');
    expect(recipe.steps.length, 3);
    expect(recipe.steps[0].order, 1);
    expect(recipe.steps[0].text, '팬을 달군 뒤 기름을 두른다.');
    expect(recipe.steps[0].baseTimeSec, 30);
    expect(recipe.steps[0].actionTag, 'heat');
  });
}
import 'package:flutter/foundation.dart';

@immutable
class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.servingsBase,
    required this.ingredients,
    required this.steps,
    this.youtubeUrl,
  });

  final String id;
  final String title;
  final int servingsBase;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final String? youtubeUrl;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      servingsBase: json['servings_base'] as int,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      youtubeUrl: json['youtube_url'] as String?,
    );
  }
}

@immutable
class Ingredient {
  const Ingredient({
    required this.name,
    required this.qty,
    required this.unit,
  });

  final String name;
  final num qty;
  final String unit;

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      qty: json['qty'] as num,
      unit: json['unit'] as String,
    );
  }
}

@immutable
class RecipeStep {
  const RecipeStep({
    required this.order,
    required this.text,
    required this.baseTimeSec,
    required this.actionTag,
  });

  final int order;
  final String text;
  final int baseTimeSec;
  final String actionTag;

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      order: json['order'] as int,
      text: json['text'] as String,
      baseTimeSec: json['base_time_sec'] as int,
      actionTag: json['action_tag'] as String,
    );
  }
}

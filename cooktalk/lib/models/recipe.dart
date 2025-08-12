import 'dart:convert';
import 'package:flutter/foundation.dart';

class Recipe {
  final String id;
  final String title;
  final int servingsBase;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;

  Recipe({
    required this.id,
    required this.title,
    required this.servingsBase,
    required this.ingredients,
    required this.steps,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      servingsBase: json['servings_base'] as int,
      ingredients: (json['ingredients'] as List)
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List)
          .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'servings_base': servingsBase,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'steps': steps.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, servingsBase: $servingsBase, ingredients: $ingredients, steps: $steps)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe &&
        other.id == id &&
        other.title == title &&
        other.servingsBase == servingsBase &&
        listEquals(other.ingredients, ingredients) &&
        listEquals(other.steps, steps);
  }

  @override
  int get hashCode {
    return Object.hash(id, title, servingsBase, Object.hashAll(ingredients), Object.hashAll(steps));
  }
}

class Ingredient {
  final String name;
  final dynamic qty;
  final String unit;

  Ingredient({
    required this.name,
    required this.qty,
    required this.unit,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      qty: json['qty'],
      unit: json['unit'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'qty': qty,
      'unit': unit,
    };
  }

  @override
  String toString() {
    return 'Ingredient(name: $name, qty: $qty, unit: $unit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ingredient &&
        other.name == name &&
        other.qty == qty &&
        other.unit == unit;
  }

  @override
  int get hashCode {
    return name.hashCode ^ qty.hashCode ^ unit.hashCode;
  }
}

class RecipeStep {
  final int order;
  final String text;
  final int baseTimeSec;
  final String actionTag;

  RecipeStep({
    required this.order,
    required this.text,
    required this.baseTimeSec,
    required this.actionTag,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      order: json['order'] as int,
      text: json['text'] as String,
      baseTimeSec: json['base_time_sec'] as int,
      actionTag: json['action_tag'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'text': text,
      'base_time_sec': baseTimeSec,
      'action_tag': actionTag,
    };
  }

  @override
  String toString() {
    return 'RecipeStep(order: $order, text: $text, baseTimeSec: $baseTimeSec, actionTag: $actionTag)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecipeStep &&
        other.order == order &&
        other.text == text &&
        other.baseTimeSec == baseTimeSec &&
        other.actionTag == actionTag;
  }

  @override
  int get hashCode {
    return order.hashCode ^
        text.hashCode ^
        baseTimeSec.hashCode ^
        actionTag.hashCode;
  }
}

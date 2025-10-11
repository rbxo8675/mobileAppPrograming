import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooktalk/models/recipe.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecipeRepository {
  // Default to local JSON for MVP/offline and tests
  final bool _defaultUseFirestore = false; // Switch between local and Firestore

  Future<List<Recipe>> getRecipes({bool? useFirestore}) async {
    final flag = useFirestore ?? _defaultUseFirestore;
    if (flag) {
      try {
        return await _getRecipesFromFirestore();
      } catch (_) {
        // Fallback to local JSON if Firestore is unavailable
        return _getRecipesFromLocalJson();
      }
    }
    return _getRecipesFromLocalJson();
  }

  Future<List<Recipe>> _getRecipesFromLocalJson() async {
    final jsonString = await rootBundle.loadString('data/recipes.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => Recipe.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Recipe>> _getRecipesFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('recipes').get();
    return snapshot.docs.map((doc) => Recipe.fromJson(doc.data())).toList();
  }

  // Returns local(default/Firestore fallback) + user-added recipes (from SharedPreferences)
  Future<List<Recipe>> getAllRecipes({bool? useFirestore}) async {
    final base = await getRecipes(useFirestore: useFirestore);
    final user = await _getUserRecipesFromPrefs();
    // De-duplicate by id, preferring user items
    final map = {for (final r in base) r.id: r};
    for (final r in user) {
      map[r.id] = r;
    }
    return map.values.toList();
  }

  Future<List<Recipe>> _getUserRecipesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_recipes');
    if (raw == null || raw.isEmpty) return [];
    final list = json.decode(raw) as List<dynamic>;
    return list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveUserRecipe(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_recipes');
    final List<dynamic> list = raw == null || raw.isEmpty ? [] : json.decode(raw) as List<dynamic>;
    // Replace by id if exists
    int idx = list.indexWhere((e) => (e as Map<String, dynamic>)['id'] == recipe.id);
    final jsonMap = {
      'id': recipe.id,
      'title': recipe.title,
      'servings_base': recipe.servingsBase,
      'ingredients': recipe.ingredients
          .map((i) => {'name': i.name, 'qty': i.qty, 'unit': i.unit})
          .toList(),
      'steps': recipe.steps
          .map((s) => {
                'order': s.order,
                'text': s.text,
                'base_time_sec': s.baseTimeSec,
                'action_tag': s.actionTag,
              })
          .toList(),
    };
    if (idx >= 0) {
      list[idx] = jsonMap;
    } else {
      list.add(jsonMap);
    }
    await prefs.setString('user_recipes', json.encode(list));
  }
}

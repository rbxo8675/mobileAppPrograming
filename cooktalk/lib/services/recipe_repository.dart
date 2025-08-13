import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooktalk/models/recipe.dart';
import 'package:flutter/services.dart';

class RecipeRepository {
  final bool _useFirestore = false; // Switch between local and Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Recipe>> getRecipes() async {
    if (_useFirestore) {
      return _getRecipesFromFirestore();
    } else {
      return _getRecipesFromLocalJson();
    }
  }

  Future<List<Recipe>> _getRecipesFromLocalJson() async {
    final jsonString = await rootBundle.loadString('data/recipes.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => Recipe.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Recipe>> _getRecipesFromFirestore() async {
    final snapshot = await _firestore.collection('recipes').get();
    return snapshot.docs.map((doc) => Recipe.fromJson(doc.data())).toList();
  }
}

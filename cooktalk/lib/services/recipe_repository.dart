import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:cooktalk/models/recipe.dart';

class RecipeRepository {
  static const String _localDataPath = 'data/recipes.json';
  static const String _firestoreCollection = 'recipes';
  
  // 데이터 소스 전환 플래그 (초기: 로컬)
  bool _useLocalData = true;
  
  bool get useLocalData => _useLocalData;
  
  void toggleDataSource() {
    _useLocalData = !_useLocalData;
  }
  
  void setDataSource(bool useLocal) {
    _useLocalData = useLocal;
  }

  /// 로컬 JSON 파일에서 레시피 목록을 로드합니다.
  Future<List<Recipe>> getRecipes() async {
    if (_useLocalData) {
      return await _loadFromLocal();
    } else {
      return await _loadFromFirestore();
    }
  }

  /// 특정 레시피를 ID로 조회합니다.
  Future<Recipe?> getRecipeById(String id) async {
    final recipes = await getRecipes();
    try {
      return recipes.firstWhere((recipe) => recipe.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 로컬 JSON 파일에서 데이터를 로드합니다.
  Future<List<Recipe>> _loadFromLocal() async {
    try {
      // Flutter의 rootBundle을 사용하여 assets에서 파일을 읽습니다.
      final String jsonString = await rootBundle.loadString(_localDataPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      
      return jsonList
          .map((json) => Recipe.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading local recipes: $e');
      // 에러 발생 시 빈 리스트 반환
      return [];
    }
  }

  /// Firestore에서 데이터를 로드합니다. (후행 구현)
  Future<List<Recipe>> _loadFromFirestore() async {
    // TODO: Firestore 구현 후 이 부분을 구현
    // 현재는 로컬 데이터를 반환
    print('Firestore loading not implemented yet, falling back to local data');
    return await _loadFromLocal();
  }

  /// 레시피 검색 기능 (제목 기반)
  Future<List<Recipe>> searchRecipes(String query) async {
    final recipes = await getRecipes();
    if (query.isEmpty) return recipes;
    
    return recipes
        .where((recipe) => 
            recipe.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// 인분 수에 따른 재료 양을 조정합니다.
  List<Ingredient> scaleIngredients(List<Ingredient> ingredients, int servings, int baseServings) {
    if (servings == baseServings) return ingredients;
    
    final scaleFactor = servings / baseServings;
    
    return ingredients.map((ingredient) {
      dynamic scaledQty;
      
      if (ingredient.qty is num) {
        scaledQty = (ingredient.qty as num) * scaleFactor;
        // 소수점이 0.5 이하인 경우 반올림
        if (scaledQty is double && scaledQty % 1 != 0) {
          scaledQty = (scaledQty * 2).round() / 2;
        }
      } else {
        // 숫자가 아닌 경우 (예: "적당량") 그대로 유지
        scaledQty = ingredient.qty;
      }
      
      return Ingredient(
        name: ingredient.name,
        qty: scaledQty,
        unit: ingredient.unit,
      );
    }).toList();
  }

  /// 레시피의 총 조리 시간을 계산합니다.
  int calculateTotalTime(Recipe recipe) {
    return recipe.steps.fold(0, (total, step) => total + step.baseTimeSec);
  }

  /// 레시피의 난이도를 계산합니다. (단계 수와 총 시간 기반)
  String calculateDifficulty(Recipe recipe) {
    final totalTime = calculateTotalTime(recipe);
    final stepCount = recipe.steps.length;
    
    if (stepCount <= 3 && totalTime <= 300) return '쉬움';
    if (stepCount <= 5 && totalTime <= 600) return '보통';
    return '어려움';
  }
}

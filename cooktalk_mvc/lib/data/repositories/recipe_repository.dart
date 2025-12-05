import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/recipe.dart';
import '../../models/user_preferences.dart';
import '../services/recipe_service.dart';
import '../database/app_database.dart';
import 'firestore_recipe_repository.dart';
import '../../core/utils/logger.dart';

class RecipeRepository {
  final RecipeService _service = RecipeService();
  final AppDatabase _database = AppDatabase();
  final FirestoreRecipeRepository _firestoreRepo = FirestoreRecipeRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;
  String? get currentUserId => _currentUserId;
  bool get _isAuthenticated => _currentUserId != null;

  Future<List<Recipe>> getExploreRecipes() async {
    try {
      Logger.info('Fetching explore recipes');
      return await _service.fetchExplore();
    } catch (e) {
      Logger.error('Failed to fetch explore recipes', e);
      rethrow;
    }
  }

  Future<List<Recipe>> getPersonalizedRecommendations({
    UserPreferences? preferences,
    String? timeOfDay,
  }) async {
    try {
      Logger.info('Fetching personalized recommendations');
      var recipes = await _service.fetchExplore();
      
      if (preferences != null && preferences.favoriteTags.isNotEmpty) {
        recipes.sort((a, b) {
          final aScore = _calculateRecommendationScore(a, preferences, timeOfDay);
          final bScore = _calculateRecommendationScore(b, preferences, timeOfDay);
          return bScore.compareTo(aScore);
        });
      }
      
      return recipes;
    } catch (e) {
      Logger.error('Failed to fetch personalized recommendations', e);
      rethrow;
    }
  }

  int _calculateRecommendationScore(Recipe recipe, UserPreferences preferences, String? timeOfDay) {
    int score = 0;
    
    for (final tag in recipe.tags) {
      if (preferences.favoriteTags.contains(tag)) {
        score += 10;
      }
    }
    
    if (timeOfDay != null) {
      if (timeOfDay == '아침' && recipe.tags.any((t) => ['간단', '빠른', '아침'].contains(t))) {
        score += 5;
      } else if (timeOfDay == '저녁' && recipe.tags.any((t) => ['저녁', '메인', '식사'].contains(t))) {
        score += 5;
      }
    }
    
    if (recipe.durationMinutes <= 30) {
      score += 3;
    }
    
    return score;
  }

  Future<List<Recipe>> getTrendingRecipes() async {
    try {
      Logger.info('Fetching trending recipes');
      return await _service.fetchTrending();
    } catch (e) {
      Logger.error('Failed to fetch trending recipes', e);
      rethrow;
    }
  }

  Future<List<Recipe>> getAllRecipes() async {
    try {
      // 1. Firestore에서 사용자의 레시피 가져오기 (우선순위)
      if (_isAuthenticated) {
        final firestoreRecipes = await _firestoreRepo.getRecipesByAuthor(_currentUserId!);
        
        // 2. 로컬 캐시에도 저장 (오프라인 지원)
        if (!kIsWeb) {
          for (final recipe in firestoreRecipes) {
            await _database.upsertRecipe(recipe);
          }
        }
        
        return firestoreRecipes;
      }
      
      // 3. 비로그인 상태면 로컬 DB 사용 (폴백)
      if (kIsWeb) {
        Logger.info('Web platform with no auth - returning empty list');
        return [];
      }
      return await _database.getAllRecipes();
    } catch (e) {
      Logger.error('Failed to get all recipes', e);
      // 에러 발생 시 로컬 DB 폴백
      if (!kIsWeb) {
        return await _database.getAllRecipes();
      }
      return [];
    }
  }

  Future<Recipe?> getRecipeById(String id) async {
    try {
      Logger.info('Fetching recipe by id: $id');
      
      // 1. Firestore에서 먼저 시도
      if (_isAuthenticated) {
        final recipe = await _firestoreRepo.getRecipeById(id);
        if (recipe != null) {
          // 로컬 캐시에 저장
          if (!kIsWeb) {
            await _database.upsertRecipe(recipe);
          }
          return recipe;
        }
      }
      
      // 2. 로컬 DB 폴백
      if (kIsWeb) {
        return null;
      }
      return await _database.getRecipeById(id);
    } catch (e) {
      Logger.error('Failed to fetch recipe by id', e);
      // 에러 시 로컬 폴백
      if (!kIsWeb) {
        return await _database.getRecipeById(id);
      }
      return null;
    }
  }

  Future<void> saveRecipe(Recipe recipe) async {
    try {
      Logger.info('Saving recipe: ${recipe.title}');
      
      // 1. Firestore에 저장 (인증된 사용자만)
      if (_isAuthenticated) {
        await _firestoreRepo.createRecipe(recipe, _currentUserId!);
        Logger.info('Recipe saved to Firestore');
      }
      
      // 2. 로컬 캐시에도 저장 (오프라인 지원)
      if (!kIsWeb) {
        await _database.insertRecipe(recipe);
        Logger.info('Recipe saved to local DB');
      }
    } catch (e) {
      Logger.error('Failed to save recipe', e);
      rethrow;
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    try {
      Logger.info('Updating recipe: ${recipe.title}');
      
      // 1. Firestore 업데이트
      if (_isAuthenticated && recipe.id.isNotEmpty) {
        await _firestoreRepo.updateRecipe(recipe.id, recipe);
        Logger.info('Recipe updated in Firestore');
      }
      
      // 2. 로컬 DB 업데이트
      if (!kIsWeb) {
        await _database.updateRecipe(recipe);
        Logger.info('Recipe updated in local DB');
      }
    } catch (e) {
      Logger.error('Failed to update recipe', e);
      rethrow;
    }
  }

  Future<void> deleteRecipe(String id) async {
    try {
      Logger.info('Deleting recipe: $id');
      
      // 1. Firestore에서 삭제
      if (_isAuthenticated) {
        await _firestoreRepo.deleteRecipe(id, _currentUserId!);
        Logger.info('Recipe deleted from Firestore');
      }
      
      // 2. 로컬 DB에서 삭제
      if (!kIsWeb) {
        await _database.deleteRecipe(id);
        Logger.info('Recipe deleted from local DB');
      }
    } catch (e) {
      Logger.error('Failed to delete recipe', e);
      rethrow;
    }
  }

  Future<void> toggleBookmark(String id, bool bookmarked) async {
    try {
      // 1. Firestore 업데이트
      if (_isAuthenticated) {
        await _firestoreRepo.toggleBookmark(id, _currentUserId!, bookmarked);
        Logger.info('Bookmark toggled in Firestore');
      }
      
      // 2. 로컬 DB 업데이트
      if (!kIsWeb) {
        await _database.toggleBookmark(id, bookmarked);
        Logger.info('Bookmark toggled in local DB');
      }
    } catch (e) {
      Logger.error('Failed to toggle bookmark', e);
      rethrow;
    }
  }

  Future<void> toggleLike(String id, bool liked) async {
    try {
      // 1. Firestore 업데이트
      if (_isAuthenticated) {
        await _firestoreRepo.toggleLike(id, _currentUserId!, liked);
        Logger.info('Like toggled in Firestore');
      }
      
      // 2. 로컬 DB 업데이트
      if (!kIsWeb) {
        await _database.toggleLike(id, liked);
        Logger.info('Like toggled in local DB');
      }
    } catch (e) {
      Logger.error('Failed to toggle like', e);
      rethrow;
    }
  }

  Future<List<Recipe>> getBookmarkedRecipes() async {
    try {
      if (_isAuthenticated) {
        return await _firestoreRepo.getBookmarkedRecipes(_currentUserId!);
      }
      return [];
    } catch (e) {
      Logger.error('Failed to get bookmarked recipes', e);
      return [];
    }
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      Logger.info('Searching recipes: $query');
      if (kIsWeb) {
        Logger.info('Skipping local DB searchRecipes on web');
        return [];
      }
      return await _database.searchRecipes(query);
    } catch (e) {
      Logger.error('Failed to search recipes', e);
      return [];
    }
  }

  Future<void> addCookingHistory({
    required String recipeId,
    String? photoPath,
    int? rating,
    String? notes,
  }) async {
    try {
      if (kIsWeb) {
        Logger.info('Skipping local DB addCookingHistory on web');
        return;
      }
      await _database.addCookingHistory(
        recipeId: recipeId,
        photoPath: photoPath,
        rating: rating,
        notes: notes,
      );
    } catch (e) {
      Logger.error('Failed to add cooking history', e);
      rethrow;
    }
  }
}

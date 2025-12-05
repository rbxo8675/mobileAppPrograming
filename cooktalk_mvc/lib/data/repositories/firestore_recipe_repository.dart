import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/recipe.dart';
import '../../models/user_preferences.dart';
import '../services/firestore_service.dart';
import '../../core/utils/logger.dart';

class FirestoreRecipeRepository {
  final FirestoreService _firestoreService = FirestoreService();

  /// Ensures user document exists, creates if not
  Future<void> _ensureUserDocumentExists(String userId) async {
    try {
      final userDoc = await _firestoreService.getDocument('users', userId);
      
      if (!userDoc.exists) {
        Logger.info('User document not found, creating: $userId');
        final currentUser = FirebaseAuth.instance.currentUser;
        
        await _firestoreService.setDocument('users', userId, {
          'uid': userId,
          'displayName': currentUser?.displayName ?? 'Anonymous User',
          'email': currentUser?.email ?? '',
          'photoURL': currentUser?.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdRecipeCount': 0,
          'likedRecipeCount': 0,
          'bookmarkedRecipeCount': 0,
        });
        Logger.info('User document created successfully');
      }
    } catch (e) {
      Logger.warning('Failed to ensure user document exists: $e');
    }
  }

  Future<Recipe> createRecipe(Recipe recipe, String userId) async {
    try {
      Logger.info('Creating recipe: ${recipe.title}');
      
      // Ensure user document exists before incrementing
      await _ensureUserDocumentExists(userId);
      
      final recipeData = recipe.copyWith(
        authorId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toFirestore();

      final docRef = await _firestoreService.addDocument('recipes', recipeData);
      
      try {
        await _firestoreService.incrementField('users', userId, 'createdRecipeCount', 1);
      } catch (e) {
        Logger.warning('Failed to increment user recipe count, but recipe was created: $e');
      }
      
      Logger.info('Recipe created with ID: ${docRef.id}');
      
      final snapshot = await docRef.get();
      return Recipe.fromFirestore(snapshot);
    } catch (e) {
      Logger.error('Failed to create recipe', e);
      rethrow;
    }
  }

  Future<Recipe?> getRecipeById(String recipeId) async {
    try {
      Logger.info('Getting recipe: $recipeId');
      final snapshot = await _firestoreService.getDocument('recipes', recipeId);
      
      if (!snapshot.exists) {
        Logger.info('Recipe not found: $recipeId');
        return null;
      }

      await _firestoreService.incrementField('recipes', recipeId, 'viewCount', 1);
      
      return Recipe.fromFirestore(snapshot);
    } catch (e) {
      Logger.error('Failed to get recipe', e);
      return null;
    }
  }

  Stream<Recipe?> streamRecipe(String recipeId) {
    Logger.info('Streaming recipe: $recipeId');
    return _firestoreService.streamDocument('recipes', recipeId).map((snapshot) {
      if (!snapshot.exists) return null;
      return Recipe.fromFirestore(snapshot);
    });
  }

  Future<List<Recipe>> getRecipes({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? orderBy,
    bool descending = true,
  }) async {
    try {
      Logger.info('Getting recipes with limit: $limit');
      
      final snapshot = await _firestoreService.getCollection(
        'recipes',
        queryBuilder: (collection) {
          Query<Map<String, dynamic>> query = collection
              .where('isPublic', isEqualTo: true)
              .orderBy(orderBy ?? 'createdAt', descending: descending)
              .limit(limit);

          if (startAfter != null) {
            query = query.startAfterDocument(startAfter);
          }

          return query;
        },
      );

      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get recipes', e);
      return [];
    }
  }

  Stream<List<Recipe>> streamRecipes({
    int limit = 20,
    String? orderBy,
    bool descending = true,
  }) {
    Logger.info('Streaming recipes with limit: $limit');
    
    return _firestoreService.streamCollection(
      'recipes',
      queryBuilder: (collection) {
        return collection
            .where('isPublic', isEqualTo: true)
            .orderBy(orderBy ?? 'createdAt', descending: descending)
            .limit(limit);
      },
    ).map((snapshot) {
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    });
  }

  Future<List<Recipe>> getRecipesByAuthor(String userId, {int limit = 20}) async {
    try {
      Logger.info('Getting recipes by author: $userId');
      
      final snapshot = await _firestoreService.getCollection(
        'recipes',
        queryBuilder: (collection) {
          return collection
              .where('authorId', isEqualTo: userId)
              .limit(limit);
        },
      );

      final recipes = snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
      // Client-side sorting to avoid index issues
      recipes.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      
      return recipes;
    } catch (e) {
      Logger.error('Failed to get recipes by author', e);
      return [];
    }
  }

  Future<List<Recipe>> getTrendingRecipes({int limit = 20}) async {
    try {
      Logger.info('Getting trending recipes');
      
      final snapshot = await _firestoreService.getCollection(
        'recipes',
        queryBuilder: (collection) {
          return collection
              .where('isPublic', isEqualTo: true)
              .orderBy('likeCount', descending: true)
              .limit(limit);
        },
      );

      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error('Failed to get trending recipes', e);
      return [];
    }
  }

  Future<List<Recipe>> getPersonalizedRecommendations({
    UserPreferences? preferences,
    String? timeOfDay,
    int limit = 20,
  }) async {
    try {
      Logger.info('Getting personalized recommendations');
      
      var recipes = await getRecipes(limit: limit * 2);

      if (preferences != null && preferences.favoriteTags.isNotEmpty) {
        recipes.sort((a, b) {
          final aScore = _calculateRecommendationScore(a, preferences, timeOfDay);
          final bScore = _calculateRecommendationScore(b, preferences, timeOfDay);
          return bScore.compareTo(aScore);
        });
      }

      return recipes.take(limit).toList();
    } catch (e) {
      Logger.error('Failed to get personalized recommendations', e);
      return [];
    }
  }

  int _calculateRecommendationScore(
    Recipe recipe,
    UserPreferences preferences,
    String? timeOfDay,
  ) {
    int score = 0;

    for (final tag in recipe.tags) {
      if (preferences.favoriteTags.contains(tag)) {
        score += 10;
      }
    }

    if (timeOfDay != null) {
      if (timeOfDay == '아침' &&
          recipe.tags.any((t) => ['간단', '빠른', '아침'].contains(t))) {
        score += 5;
      } else if (timeOfDay == '저녁' &&
          recipe.tags.any((t) => ['저녁', '메인', '식사'].contains(t))) {
        score += 5;
      }
    }

    if (recipe.durationMinutes <= 30) {
      score += 3;
    }

    score += (recipe.likeCount / 10).round();

    return score;
  }

  Future<List<Recipe>> searchRecipes(String query, {int limit = 20}) async {
    try {
      Logger.info('Searching recipes: $query');
      
      final allRecipes = await getRecipes(limit: 100);
      
      final filtered = allRecipes.where((recipe) {
        final titleMatch = recipe.title.toLowerCase().contains(query.toLowerCase());
        final ingredientMatch = recipe.ingredients
            .any((i) => i.toLowerCase().contains(query.toLowerCase()));
        final tagMatch =
            recipe.tags.any((t) => t.toLowerCase().contains(query.toLowerCase()));
        
        return titleMatch || ingredientMatch || tagMatch;
      }).toList();

      return filtered.take(limit).toList();
    } catch (e) {
      Logger.error('Failed to search recipes', e);
      return [];
    }
  }

  Future<void> updateRecipe(String recipeId, Recipe recipe) async {
    try {
      Logger.info('Updating recipe: $recipeId');
      
      final updates = recipe.copyWith(updatedAt: DateTime.now()).toFirestore();
      await _firestoreService.updateDocument('recipes', recipeId, updates);
      
      Logger.info('Recipe updated successfully');
    } catch (e) {
      Logger.error('Failed to update recipe', e);
      rethrow;
    }
  }

  Future<void> deleteRecipe(String recipeId, String userId) async {
    try {
      Logger.info('Deleting recipe: $recipeId');
      
      await _firestoreService.deleteDocument('recipes', recipeId);
      
      try {
        await _ensureUserDocumentExists(userId);
        await _firestoreService.incrementField('users', userId, 'createdRecipeCount', -1);
      } catch (e) {
        Logger.warning('Failed to decrement user recipe count: $e');
      }
      
      Logger.info('Recipe deleted successfully');
    } catch (e) {
      Logger.error('Failed to delete recipe', e);
      rethrow;
    }
  }

  Future<void> toggleLike(String recipeId, String userId, bool liked) async {
    try {
      Logger.info('Toggling like for recipe: $recipeId');
      
      final likeId = '${userId}_$recipeId';
      
      if (liked) {
        await _firestoreService.setDocument('likes', likeId, {
          'userId': userId,
          'targetId': recipeId,
          'targetType': 'recipe',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        await _firestoreService.incrementField('recipes', recipeId, 'likeCount', 1);
      } else {
        await _firestoreService.deleteDocument('likes', likeId);
        await _firestoreService.incrementField('recipes', recipeId, 'likeCount', -1);
      }
      
      Logger.info('Like toggled successfully');
    } catch (e) {
      Logger.error('Failed to toggle like', e);
      rethrow;
    }
  }

  Future<void> toggleBookmark(String recipeId, String userId, bool bookmarked) async {
    try {
      Logger.info('Toggling bookmark for recipe: $recipeId (bookmarked: $bookmarked)');
      
      // Verify user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Cannot toggle bookmark: User not authenticated');
      }
      
      final bookmarkId = '${userId}_$recipeId';
      
      if (bookmarked) {
        await _firestoreService.setDocument('bookmarks', bookmarkId, {
          'userId': userId,
          'recipeId': recipeId,
          'collectionName': 'default',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        await _firestoreService.incrementField('recipes', recipeId, 'bookmarkCount', 1);
      } else {
        await _firestoreService.deleteDocument('bookmarks', bookmarkId);
        await _firestoreService.incrementField('recipes', recipeId, 'bookmarkCount', -1);
      }
      
      Logger.info('Bookmark toggled successfully');
    } catch (e, stackTrace) {
      Logger.error('Failed to toggle bookmark: $e', stackTrace);
      rethrow;
    }
  }

  Future<List<Recipe>> getBookmarkedRecipes(String userId, {int limit = 20}) async {
    try {
      Logger.info('Getting bookmarked recipes for user: $userId');
      
      // Verify user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Logger.warning('Cannot get bookmarked recipes: User not authenticated');
        return [];
      }
      
      if (currentUser.uid != userId) {
        Logger.warning('User ID mismatch: ${currentUser.uid} != $userId');
      }
      
      final bookmarkSnapshot = await _firestoreService.getCollection(
        'bookmarks',
        queryBuilder: (collection) {
          return collection
              .where('userId', isEqualTo: userId)
              .limit(limit);
        },
      );

      final bookmarks = bookmarkSnapshot.docs.toList();
      Logger.info('Found ${bookmarks.length} bookmarks for user');
      
      // Client-side sorting to avoid composite index requirement
      bookmarks.sort((a, b) {
        final aTime = a.data()['createdAt'] as Timestamp?;
        final bTime = b.data()['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      final recipeIds = bookmarks
          .map((doc) => doc.data()['recipeId'] as String)
          .toList();

      if (recipeIds.isEmpty) return [];

      final recipes = await Future.wait(
        recipeIds.map((id) => getRecipeById(id)),
      );

      return recipes.whereType<Recipe>().toList();
    } catch (e, stackTrace) {
      Logger.error('Failed to get bookmarked recipes: $e', stackTrace);
      return [];
    }
  }

  Future<bool> isRecipeLiked(String recipeId, String userId) async {
    try {
      final likeId = '${userId}_$recipeId';
      final snapshot = await _firestoreService.getDocument('likes', likeId);
      return snapshot.exists;
    } catch (e) {
      Logger.error('Failed to check if recipe is liked', e);
      return false;
    }
  }

  Future<bool> isRecipeBookmarked(String recipeId, String userId) async {
    try {
      final bookmarkId = '${userId}_$recipeId';
      final snapshot = await _firestoreService.getDocument('bookmarks', bookmarkId);
      return snapshot.exists;
    } catch (e) {
      Logger.error('Failed to check if recipe is bookmarked', e);
      return false;
    }
  }
}

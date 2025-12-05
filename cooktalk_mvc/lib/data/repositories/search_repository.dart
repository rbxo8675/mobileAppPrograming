import '../../models/recipe.dart';
import '../../core/utils/logger.dart';

class SearchRepository {
  List<Recipe> searchByText(List<Recipe> recipes, String query) {
    if (query.trim().isEmpty) return recipes;
    
    final lowerQuery = query.toLowerCase();
    return recipes.where((r) {
      return r.title.toLowerCase().contains(lowerQuery) ||
          (r.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          r.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }
  
  List<Recipe> searchByIngredients(
    List<Recipe> recipes,
    List<String> ingredients,
  ) {
    if (ingredients.isEmpty) return recipes;
    
    Logger.debug('Searching by ingredients: $ingredients');
    
    return recipes.where((recipe) {
      final hasAllIngredients = ingredients.every((searchIng) {
        return recipe.ingredients.any((recipeIng) =>
          recipeIng.toLowerCase().contains(searchIng.toLowerCase())
        );
      });
      return hasAllIngredients;
    }).toList();
  }
  
  List<Recipe> searchByTags(List<Recipe> recipes, List<String> tags) {
    if (tags.isEmpty) return recipes;
    
    return recipes.where((recipe) {
      return tags.any((tag) =>
        recipe.tags.any((recipeTag) =>
          recipeTag.toLowerCase().contains(tag.toLowerCase())
        )
      );
    }).toList();
  }
  
  List<Recipe> filterByTime(List<Recipe> recipes, int maxMinutes) {
    return recipes.where((r) => r.durationMinutes <= maxMinutes).toList();
  }
  
  List<Recipe> filterByDifficulty(List<Recipe> recipes, String difficulty) {
    return recipes.where((r) => r.difficulty == difficulty).toList();
  }
  
  List<Recipe> filterByServings(List<Recipe> recipes, int servings) {
    return recipes.where((r) => 
      r.servings != null && r.servings! <= servings
    ).toList();
  }
  
  List<Recipe> combineFilters({
    required List<Recipe> recipes,
    String? textQuery,
    List<String>? ingredients,
    List<String>? tags,
    int? maxTime,
    String? difficulty,
    int? maxServings,
  }) {
    var filtered = recipes;
    
    if (textQuery != null && textQuery.isNotEmpty) {
      filtered = searchByText(filtered, textQuery);
    }
    
    if (ingredients != null && ingredients.isNotEmpty) {
      filtered = searchByIngredients(filtered, ingredients);
    }
    
    if (tags != null && tags.isNotEmpty) {
      filtered = searchByTags(filtered, tags);
    }
    
    if (maxTime != null) {
      filtered = filterByTime(filtered, maxTime);
    }
    
    if (difficulty != null) {
      filtered = filterByDifficulty(filtered, difficulty);
    }
    
    if (maxServings != null) {
      filtered = filterByServings(filtered, maxServings);
    }
    
    Logger.info('Search results: ${filtered.length} recipes found');
    return filtered;
  }
  
  List<String> getSuggestedIngredients(List<Recipe> recipes) {
    final allIngredients = <String>{};
    
    for (final recipe in recipes) {
      for (final ingredient in recipe.ingredients) {
        final cleaned = ingredient.toLowerCase().trim();
        allIngredients.add(cleaned);
      }
    }
    
    return allIngredients.toList()..sort();
  }
  
  List<String> getPopularTags(List<Recipe> recipes) {
    final tagCount = <String, int>{};
    
    for (final recipe in recipes) {
      for (final tag in recipe.tags) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }
    
    final sorted = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.map((e) => e.key).take(20).toList();
  }
}

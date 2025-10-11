import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/feed_post.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/feed_repository.dart';
import '../data/services/youtube_service.dart';
import '../core/utils/logger.dart';

class RecipeController extends ChangeNotifier {
  final _recipeRepo = RecipeRepository();
  final _feedRepo = FeedRepository();
  final _youtube = YouTubeService();

  List<Recipe> _explore = [];
  List<Recipe> _trending = [];
  List<Recipe> _myRecipes = [];
  List<FeedPost> _feed = [];
  final Set<String> _completed = {};

  bool _loadingExplore = false;
  bool _loadingTrending = false;
  bool _loadingFeed = false;

  List<Recipe> get explore => _explore;
  List<Recipe> get trending => _trending;
  List<Recipe> get myRecipes => _myRecipes;
  List<FeedPost> get feed => _feed;

  bool get loadingExplore => _loadingExplore;
  bool get loadingTrending => _loadingTrending;
  bool get loadingFeed => _loadingFeed;
  int get completedCount => _completed.length;

  Future<void> bootstrap() async {
    await Future.wait([loadExplore(), loadTrending(), loadFeed()]);
  }

  Future<void> loadExplore() async {
    try {
      _loadingExplore = true;
      notifyListeners();
      _explore = await _recipeRepo.getExploreRecipes();
    } catch (e) {
      Logger.error('Failed to load explore recipes', e);
      _explore = [];
    } finally {
      _loadingExplore = false;
      notifyListeners();
    }
  }

  Future<void> loadTrending() async {
    try {
      _loadingTrending = true;
      notifyListeners();
      _trending = await _recipeRepo.getTrendingRecipes();
    } catch (e) {
      Logger.error('Failed to load trending recipes', e);
      _trending = [];
    } finally {
      _loadingTrending = false;
      notifyListeners();
    }
  }

  Future<void> loadFeed() async {
    try {
      _loadingFeed = true;
      notifyListeners();
      _feed = await _feedRepo.getFeedPosts();
    } catch (e) {
      Logger.error('Failed to load feed', e);
      _feed = [];
    } finally {
      _loadingFeed = false;
      notifyListeners();
    }
  }

  Recipe? getById(String id) {
    return _explore.cast<Recipe?>()
        .followedBy(_trending)
        .followedBy(_myRecipes)
        .firstWhere((r) => r?.id == id, orElse: () => null);
  }

  void toggleLike(Recipe r) {
    final isLiked = !r.liked;
    Logger.debug('Toggling like for recipe: ${r.title} (isLiked: $isLiked)');

    _updateRecipeInLists(r.id, (recipe) => recipe.copyWith(liked: isLiked));
    _handleMyRecipeUpdate(r, liked: isLiked);
    
    notifyListeners();
  }

  void togglePostLike(FeedPost p) {
    final idx = _feed.indexWhere((e) => e.id == p.id);
    if (idx == -1) return;
    final liked = !p.liked;
    final delta = liked ? 1 : -1;
    _feed = [
      ..._feed.take(idx),
      p.copyWith(liked: liked, likes: p.likes + delta),
      ..._feed.skip(idx + 1),
    ];
    notifyListeners();
  }

  void togglePostBookmark(FeedPost p) {
    final idx = _feed.indexWhere((e) => e.id == p.id);
    if (idx == -1) return;
    _feed = [
      ..._feed.take(idx),
      p.copyWith(bookmarked: !p.bookmarked),
      ..._feed.skip(idx + 1),
    ];
    notifyListeners();
  }

  bool toggleBookmark(Recipe r) {
    final bookmarked = !r.bookmarked;
    Logger.debug('Toggling bookmark for recipe: ${r.title} (bookmarked: $bookmarked)');

    _updateRecipeInLists(r.id, (recipe) => recipe.copyWith(bookmarked: bookmarked));
    _handleMyRecipeUpdate(r, bookmarked: bookmarked);
    
    notifyListeners();
    return bookmarked;
  }

  void _updateRecipeInLists(String id, Recipe Function(Recipe) updateFn) {
    _explore = _explore.map((e) => e.id == id ? updateFn(e) : e).toList();
    _trending = _trending.map((e) => e.id == id ? updateFn(e) : e).toList();
  }

  void _handleMyRecipeUpdate(Recipe r, {bool? liked, bool? bookmarked}) {
    final idx = _myRecipes.indexWhere((e) => e.id == r.id);
    final shouldBeInMyRecipes = (liked ?? r.liked) || (bookmarked ?? r.bookmarked);

    if (shouldBeInMyRecipes) {
      if (idx == -1) {
        _myRecipes = [
          ...(_myRecipes),
          r.copyWith(liked: liked ?? r.liked, bookmarked: bookmarked ?? r.bookmarked)
        ];
      } else {
        _myRecipes = [
          ..._myRecipes.take(idx),
          _myRecipes[idx].copyWith(liked: liked ?? _myRecipes[idx].liked, bookmarked: bookmarked ?? _myRecipes[idx].bookmarked),
          ..._myRecipes.skip(idx + 1),
        ];
      }
    } else {
      if (idx != -1) {
        _myRecipes = _myRecipes.where((e) => e.id != r.id).toList();
      }
    }
  }

  Future<void> importFromYouTube(String url) async {
    try {
      Logger.info('Importing recipe from YouTube: $url');
      final data = await _youtube.extractRecipeFromUrl(url);
      
      final newRecipe = Recipe(
        id: 'yt_${DateTime.now().millisecondsSinceEpoch}',
        title: data['title'] as String,
        durationMinutes: data['durationMinutes'] as int,
        ingredients: (data['ingredients'] as List).cast<String>(),
        steps: (data['steps'] as List).cast<String>(),
        imagePath: data['imagePath'] as String?,
        description: data['description'] as String?,
        servings: data['servings'] as int?,
        difficulty: data['difficulty'] as String?,
        tags: (data['tags'] as List?)?.cast<String>() ?? [],
        liked: true,
        bookmarked: true,
      );
      
      _myRecipes = [newRecipe, ..._myRecipes];
      Logger.info('Recipe imported successfully: ${newRecipe.title}');
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to import recipe from YouTube', e);
      rethrow;
    }
  }

  void addManualRecipe({
    required String title,
    required int durationMinutes,
    List<String> ingredients = const [],
    List<String> steps = const [],
    String? imagePath,
    String? description,
  }) {
    Logger.info('Adding manual recipe: $title');
    
    final recipe = Recipe(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      durationMinutes: durationMinutes,
      ingredients: ingredients,
      steps: steps,
      imagePath: imagePath,
      description: description,
      liked: true,
      bookmarked: true,
    );
    
    _myRecipes = [recipe, ..._myRecipes];
    notifyListeners();
  }

  void markCompleted(Recipe r) {
    _completed.add(r.id);
    notifyListeners();
  }
}

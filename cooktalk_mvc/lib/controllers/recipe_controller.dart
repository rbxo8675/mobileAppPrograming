import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/feed_post.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/feed_repository.dart';
import '../data/services/youtube_service.dart';
import '../core/utils/logger.dart';

/// 앱의 레시피 및 피드 관련 데이터와 비즈니스 로직을 관리하는 컨트롤러입니다.
///
/// [ChangeNotifier]를 상속하여 상태 변경 시 UI에 알림을 보냅니다.
/// 레시피 목록(탐색, 트렌딩, 내 레시피)과 소셜 피드를 관리하고,
/// '좋아요', '스크랩' 등의 사용자 활동을 처리하며 데이터베이스와 동기화합니다.
class RecipeController extends ChangeNotifier {
  // --- 의존성 ---
  RecipeRepository _recipeRepo;
  FeedRepository _feedRepo;
  YouTubeService _youtube;

  // --- 상태 변수 ---
  List<Recipe> _explore = []; // '탐색' 탭에 표시될 레시피 목록
  List<Recipe> _savedRecipes = []; // '저장됨' 탭에 표시될 북마크된 레시피 목록
  List<Recipe> _trending = []; // '트렌딩' 탭에 표시될 레시피 목록
  List<Recipe> _myRecipes = []; // '내 레시피' 탭에 표시될 내가 작성한 레시피 목록
  List<FeedPost> _feed = []; // '피드' 탭에 표시될 소셜 피드 목록
  final Set<String> _completed = {}; // 현재 세션에서 완료된 레시피 ID 집합

  // 로딩 상태
  bool _loadingExplore = false;
  bool _loadingSavedRecipes = false;
  bool _loadingTrending = false;
  bool _loadingFeed = false;
  bool _loadingMyRecipes = false;
  
  // --- Public Getters ---
  List<Recipe> get explore => _explore;
  List<Recipe> get savedRecipes => _savedRecipes;
  List<Recipe> get trending => _trending;
  List<Recipe> get myRecipes => _myRecipes;
  List<FeedPost> get feed => _feed;

  bool get loadingExplore => _loadingExplore;
  bool get loadingSavedRecipes => _loadingSavedRecipes;
  bool get loadingTrending => _loadingTrending;
  bool get loadingFeed => _loadingFeed;
  bool get loadingMyRecipes => _loadingMyRecipes;
  int get completedCount => _completed.length;

  RecipeController(this._recipeRepo, this._feedRepo, this._youtube);

  /// [ChangeNotifierProxyProvider]를 통해 Repository가 업데이트될 때 호출됩니다.
  void updateRepositories({
    RecipeRepository? recipeRepo,
    FeedRepository? feedRepo,
    YouTubeService? youtube,
  }) {
    if (recipeRepo != null) _recipeRepo = recipeRepo;
    if (feedRepo != null) _feedRepo = feedRepo;
    if (youtube != null) _youtube = youtube;
  }

  /// 앱 시작 시 필요한 초기 데이터를 로드합니다.
  Future<void> bootstrap() async {
    await Future.wait([
      loadExplore(),
      loadSavedRecipes(),
      loadTrending(),
      loadFeed(),
      loadMyRecipes(),
    ]);
  }

  /// '탐색' 탭의 레시피 목록을 불러옵니다.
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

  /// '저장됨' 탭의 북마크된 레시피 목록을 불러옵니다.
  Future<void> loadSavedRecipes() async {
    try {
      _loadingSavedRecipes = true;
      notifyListeners();
      _savedRecipes = await _recipeRepo.getBookmarkedRecipes();
    } catch (e) {
      Logger.error('Failed to load saved recipes', e);
      _savedRecipes = [];
    } finally {
      _loadingSavedRecipes = false;
      notifyListeners();
    }
  }

  /// '트렌딩' 탭의 레시피 목록을 불러옵니다.
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
  
  /// 소셜 피드 목록을 불러옵니다.
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

  /// ID로 컨트롤러가 관리하는 모든 레시피 목록에서 레시피를 찾습니다.
  Recipe? getById(String id) {
    return _explore
        .cast<Recipe?>()
        .followedBy(_savedRecipes)
        .followedBy(_trending)
        .followedBy(_myRecipes)
        .firstWhere((r) => r?.id == id, orElse: () => null);
  }

  /// 레시피의 '좋아요' 상태를 토글하고, 변경 사항을 데이터베이스에 저장합니다.
  Future<void> toggleLike(Recipe r) async {
    final isLiked = !r.liked;
    Logger.debug('Toggling like for recipe: ${r.title} (isLiked: $isLiked)');

    // 1. UI 즉각적인 반응을 위해 인메모리 상태를 먼저 업데이트합니다.
    _updateRecipeInLists(r.id, (recipe) => recipe.copyWith(liked: isLiked));
    notifyListeners(); // UI 갱신

    // 2. 변경 사항을 데이터베이스에 비동기적으로 저장합니다.
    try {
      await _recipeRepo.toggleLike(r.id, isLiked);
      Logger.info('Like status for ${r.title} saved to DB.');
    } catch (e) {
      Logger.error('Failed to save like status for ${r.title}', e);
      // TODO: 실패 시 UI 롤백 처리 (선택 사항)
    }
  }

  /// 피드 게시물의 '좋아요' 상태를 토글합니다. (데이터베이스 연동 X)
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

  /// 피드 게시물의 '스크랩' 상태를 토글합니다. (데이터베이스 연동 X)
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

  /// 레시피의 '스크랩(즐겨찾기)' 상태를 토글하고, 변경 사항을 데이터베이스에 저장합니다.
  Future<bool> toggleBookmark(Recipe r) async {
    final bookmarked = !r.bookmarked;
    Logger.debug(
      'Toggling bookmark for recipe: ${r.title} (bookmarked: $bookmarked)',
    );

    // 1. UI 즉각적인 반응을 위해 인메모리 상태를 먼저 업데이트합니다.
    _updateRecipeInLists(
      r.id,
      (recipe) => recipe.copyWith(bookmarked: bookmarked),
    );
    _handleSavedRecipesUpdate(r, bookmarked: bookmarked);
    notifyListeners(); // UI 갱신

    // 2. 변경 사항을 데이터베이스에 비동기적으로 저장합니다.
    try {
      await _recipeRepo.toggleBookmark(r.id, bookmarked);
      Logger.info('Bookmark status for ${r.title} saved to DB.');
    } catch (e) {
      Logger.error('Failed to save bookmark status for ${r.title}', e);
      // TODO: 실패 시 UI 롤백 처리 (선택 사항)
    }
    
    return bookmarked;
  }

  /// `_explore`, `_savedRecipes`, `_trending`, `_myRecipes` 목록에 있는 특정 레시피의 상태를 업데이트합니다.
  void _updateRecipeInLists(
    String id,
    Recipe Function(Recipe) updateFn,
  ) {
    _explore = _explore.map((e) => e.id == id ? updateFn(e) : e).toList();
    _savedRecipes = _savedRecipes.map((e) => e.id == id ? updateFn(e) : e).toList();
    _trending = _trending.map((e) => e.id == id ? updateFn(e) : e).toList();
    _myRecipes = _myRecipes.map((e) => e.id == id ? updateFn(e) : e).toList();
  }

  /// 북마크 상태 변경 시 `_savedRecipes` 목록을 업데이트하는 헬퍼 메소드.
  void _handleSavedRecipesUpdate(
    Recipe r, {
    required bool bookmarked,
  }) {
    final idx = _savedRecipes.indexWhere((e) => e.id == r.id);

    if (bookmarked) {
      // 북마크 추가: 목록에 없으면 추가
      if (idx == -1) {
        _savedRecipes = [
          ..._savedRecipes,
          r.copyWith(bookmarked: true),
        ];
      } else {
        // 이미 있으면 업데이트
        _savedRecipes = [
          ..._savedRecipes.take(idx),
          _savedRecipes[idx].copyWith(bookmarked: true),
          ..._savedRecipes.skip(idx + 1),
        ];
      }
    } else {
      // 북마크 해제: 목록에서 제거
      if (idx != -1) {
        _savedRecipes = _savedRecipes.where((e) => e.id != r.id).toList();
      }
    }
  }

  /// YouTube URL로부터 레시피를 추출하여 DB에 저장하고 '내 레시피' 목록에 추가합니다.
  Future<void> importFromYouTube(String url) async {
    try {
      Logger.info('Importing recipe from YouTube: $url');
      final data = await _youtube.extractRecipeFromUrl(url);

      final newRecipe = Recipe.fromStringSteps(
        id: 'yt_${DateTime.now().millisecondsSinceEpoch}',
        title: data['title'] as String,
        durationMinutes: data['durationMinutes'] as int,
        ingredients: (data['ingredients'] as List).cast<String>(),
        stringSteps: (data['steps'] as List).cast<String>(),
        imagePath: data['imagePath'] as String?,
        description: data['description'] as String?,
        servings: data['servings'] as int?,
        difficulty: data['difficulty'] as String?,
        tags: (data['tags'] as List?)?.cast<String>() ?? [],
        liked: false,
        bookmarked: false,
        authorId: _recipeRepo.currentUserId,
      );

      // 데이터베이스에 저장
      await _recipeRepo.saveRecipe(newRecipe);

      _myRecipes = [newRecipe, ..._myRecipes];
      Logger.info(
        'Recipe imported and saved successfully: ${newRecipe.title}',
      );
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to import recipe from YouTube', e);
      rethrow;
    }
  }

  /// 사용자가 직접 입력한 레시피를 DB에 저장하고 '내 레시피' 목록에 추가합니다.
  Future<void> addManualRecipe({
    required String title,
    required int durationMinutes,
    List<String> ingredients = const [],
    List<String> steps = const [],
    String? imagePath,
    String? description,
  }) async {
    try {
      Logger.info('Adding manual recipe: $title');

      final recipe = Recipe.fromStringSteps(
        id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        durationMinutes: durationMinutes,
        ingredients: ingredients,
        stringSteps: steps,
        imagePath: imagePath,
        description: description,
        liked: false,
        bookmarked: false,
        authorId: _recipeRepo.currentUserId,
      );

      // 데이터베이스에 저장
      await _recipeRepo.saveRecipe(recipe);

      _myRecipes = [recipe, ..._myRecipes];
      Logger.info(
        'Manual recipe added and saved successfully: ${recipe.title}',
      );
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to add manual recipe', e);
      rethrow;
    }
  }

  /// 레시피 정보를 업데이트합니다.
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      Logger.info('Updating recipe: ${recipe.title}');
      await _recipeRepo.updateRecipe(recipe);

      // 목록에서 업데이트
      _updateRecipeInLists(recipe.id, (_) => recipe);
      
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to update recipe', e);
      rethrow;
    }
  }

  /// 레시피를 삭제합니다.
  Future<void> deleteRecipe(String id) async {
    try {
      Logger.info('Deleting recipe: $id');
      await _recipeRepo.deleteRecipe(id);

      // 목록에서 제거
      _explore = _explore.where((r) => r.id != id).toList();
      _savedRecipes = _savedRecipes.where((r) => r.id != id).toList();
      _trending = _trending.where((r) => r.id != id).toList();
      _myRecipes = _myRecipes.where((r) => r.id != id).toList();
      
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to delete recipe', e);
      rethrow;
    }
  }

  /// 특정 레시피를 '요리 완료'로 표시하고, 이력을 데이터베이스에 저장합니다.
  Future<void> markCompleted(Recipe r) async {
    // 1. UI 즉각적인 반응을 위해 인메모리 Set에 추가
    _completed.add(r.id);
    
    // 2. 변경 사항을 데이터베이스에 비동기적으로 저장
    try {
      await _recipeRepo.addCookingHistory(recipeId: r.id);
      Logger.info('Cooking history for ${r.title} saved to DB.');
    } catch (e) {
      Logger.error('Failed to save cooking history for ${r.title}', e);
      // 실패 시, 인메모리 Set에서 다시 제거
      _completed.remove(r.id);
    }
    
    notifyListeners();
  }

  /// 데이터베이스에서 '내 레시피'(사용자가 직접 추가한 레시피) 목록을 불러옵니다.
  Future<void> loadMyRecipes() async {
    try {
      _loadingMyRecipes = true;
      notifyListeners();

      _myRecipes = await _recipeRepo.getAllRecipes();

      Logger.info(
        'Loaded ${_myRecipes.length} my recipes from database',
      );
    } catch (e) {
      Logger.error('Failed to load my recipes', e);
      _myRecipes = [];
    } finally {
      _loadingMyRecipes = false;
      notifyListeners();
    }
  }

  /// (미구현) 팔로우 중인 사용자의 피드를 불러옵니다.
  Future<void> loadFollowingFeed() async {
    // 현재는 일반 피드와 동일하게 처리
    await loadFeed();
  }

  /// (미구현) 특정 사용자를 팔로우/언팔로우합니다.
  void toggleFollowUser(String userId, bool isFollowing) {
    // TODO: 실제 팔로우 기능 구현 필요
    Logger.info('Toggle follow user: $userId (현재: $isFollowing)');
    notifyListeners();
  }
}
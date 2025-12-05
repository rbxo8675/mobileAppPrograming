import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/recipe_controller.dart';
import '../../controllers/cooking_assistant_controller.dart';

/// Provider 접근을 간편하게 해주는 BuildContext Extension
/// 
/// 사용 예시:
/// ```dart
/// // Read (일회성 접근)
/// context.auth.signIn(email, password);
/// context.recipes.toggleLike(recipe);
/// 
/// // Watch (변경사항 감지 및 자동 rebuild)
/// final user = context.watchAuth.currentUser;
/// final recipeList = context.watchRecipes.explore;
/// ```
extension ProviderExtension on BuildContext {
  // ========== Read (일회성 접근) ==========
  
  /// AppController에 접근 (테마, 탭 인덱스 등)
  AppController get app => read<AppController>();
  
  /// AuthController에 접근 (로그인, 회원가입 등)
  AuthController get auth => read<AuthController>();
  
  /// RecipeController에 접근 (레시피 목록, 좋아요, 북마크 등)
  RecipeController get recipes => read<RecipeController>();
  
  /// CookingAssistantController에 접근 (요리 가이드, 채팅 등)
  CookingAssistantController get cookingAssistant => read<CookingAssistantController>();
  
  // ========== Watch (변경사항 감지) ==========
  
  /// AppController 감시 - 변경 시 자동 rebuild
  AppController get watchApp => watch<AppController>();
  
  /// AuthController 감시 - 변경 시 자동 rebuild
  AuthController get watchAuth => watch<AuthController>();
  
  /// RecipeController 감시 - 변경 시 자동 rebuild
  RecipeController get watchRecipes => watch<RecipeController>();
  
  /// CookingAssistantController 감시 - 변경 시 자동 rebuild
  CookingAssistantController get watchCookingAssistant => watch<CookingAssistantController>();
  
  // ========== Select (특정 값만 감시) ==========
  
  /// 특정 값만 선택적으로 감시
  /// 
  /// 사용 예시:
  /// ```dart
  /// final tabIndex = context.select<AppController, int>((app) => app.tabIndex);
  /// final isLoading = context.select<RecipeController, bool>((rc) => rc.loadingExplore);
  /// ```
  T selectValue<C, T>(T Function(C) selector) => select<C, T>(selector);
}

/// Theme 관련 편의 메서드
extension ThemeExtension on BuildContext {
  /// 현재 테마의 ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// 현재 테마의 TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// 다크모드 여부
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// MediaQuery 편의 접근
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
}

/// Navigation 편의 메서드
extension NavigationExtension on BuildContext {
  /// 페이지 이동
  Future<T?> push<T>(Widget page) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }
  
  /// 페이지 교체
  Future<T?> pushReplacement<T, TO>(Widget page) {
    return Navigator.of(this).pushReplacement<T, TO>(
      MaterialPageRoute(builder: (_) => page),
    );
  }
  
  /// 뒤로가기
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }
  
  /// 스낵바 표시
  void showSnackBar(String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }
  
  /// 에러 스낵바 표시
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// 성공 스낵바 표시
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class AppConstants {
  static const String appName = 'CookTalk';
  
  static const int defaultRecipeDuration = 30;
  static const int maxRecipeSteps = 20;
  static const int maxIngredients = 50;
  
  static const List<String> difficulties = ['쉬움', '보통', '어려움'];
  
  static const int feedLoadDelay = 350;
  static const int exploreLoadDelay = 400;
  static const int trendingLoadDelay = 300;
}

class RouteNames {
  static const String home = '/';
  static const String recipeDetail = '/recipe-detail';
  static const String recipeForm = '/recipe-form';
  static const String youtubeExtract = '/youtube-extract';
  static const String cookingAssistant = '/cooking-assistant';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

class ApiConstants {
  // gemini-1.5-flash is the recommended model for google_generative_ai v0.4.7+
  // gemini-1.0-pro is deprecated
  static const String geminiModel = 'gemini-1.5-flash';
  static const int maxTokens = 2048;
  static const double temperature = 0.7;
}

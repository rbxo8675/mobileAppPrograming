class YouTubeService {
  // Stub: Replace with real server API call (e.g., POST /extract?url=...)
  Future<Map<String, dynamic>> extractRecipeFromUrl(String url) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'title': 'Sample - YouTube Parsing Result',
      'ingredients': ['Sample Ingredient A', 'Sample Ingredient B'],
      'steps': ['Sample Step 1', 'Sample Step 2'],
      'durationMinutes': 30,
    };
  }
}


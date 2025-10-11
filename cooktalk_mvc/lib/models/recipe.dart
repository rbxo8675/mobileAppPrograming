class Recipe {
  final String id;
  final String title;
  final String? imagePath;
  final int durationMinutes;
  final List<String> ingredients;
  final List<RecipeStep> steps;
  final bool liked;

  final String? description;
  final int? servings;
  final String? difficulty;
  final double? rating;
  final bool bookmarked;
  final List<String> tags;

  const Recipe({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.ingredients,
    required this.steps,
    this.imagePath,
    this.liked = false,
    this.description,
    this.servings,
    this.difficulty,
    this.rating,
    this.bookmarked = false,
    this.tags = const [],
  });
  
  factory Recipe.fromStringSteps({
    required String id,
    required String title,
    required int durationMinutes,
    required List<String> ingredients,
    required List<String> stringSteps,
    String? imagePath,
    bool liked = false,
    String? description,
    int? servings,
    String? difficulty,
    double? rating,
    bool bookmarked = false,
    List<String> tags = const [],
  }) {
    return Recipe(
      id: id,
      title: title,
      durationMinutes: durationMinutes,
      ingredients: ingredients,
      steps: stringSteps.map((s) => RecipeStep(instruction: s)).toList(),
      imagePath: imagePath,
      liked: liked,
      description: description,
      servings: servings,
      difficulty: difficulty,
      rating: rating,
      bookmarked: bookmarked,
      tags: tags,
    );
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? imagePath,
    int? durationMinutes,
    List<String>? ingredients,
    List<RecipeStep>? steps,
    bool? liked,
    String? description,
    int? servings,
    String? difficulty,
    double? rating,
    bool? bookmarked,
    List<String>? tags,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      imagePath: imagePath ?? this.imagePath,
      liked: liked ?? this.liked,
      description: description ?? this.description,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      rating: rating ?? this.rating,
      bookmarked: bookmarked ?? this.bookmarked,
      tags: tags ?? this.tags,
    );
  }
  
  List<String> get stepsAsStrings => steps.map((s) => s.instruction).toList();
}

class RecipeStep {
  final String instruction;
  final int? timerMinutes;
  final bool autoStart;

  const RecipeStep({
    required this.instruction,
    this.timerMinutes,
    this.autoStart = false,
  });
  
  RecipeStep copyWith({
    String? instruction,
    int? timerMinutes,
    bool? autoStart,
  }) {
    return RecipeStep(
      instruction: instruction ?? this.instruction,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      autoStart: autoStart ?? this.autoStart,
    );
  }
}


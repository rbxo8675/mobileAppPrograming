class UserPreferences {
  final List<String> favoriteTags;
  final List<String> recentlyCooked;
  final int weeklyGoal;
  final String? dietaryRestriction;
  final List<String> excludedIngredients;

  const UserPreferences({
    this.favoriteTags = const [],
    this.recentlyCooked = const [],
    this.weeklyGoal = 7,
    this.dietaryRestriction,
    this.excludedIngredients = const [],
  });

  UserPreferences copyWith({
    List<String>? favoriteTags,
    List<String>? recentlyCooked,
    int? weeklyGoal,
    String? dietaryRestriction,
    List<String>? excludedIngredients,
  }) {
    return UserPreferences(
      favoriteTags: favoriteTags ?? this.favoriteTags,
      recentlyCooked: recentlyCooked ?? this.recentlyCooked,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      dietaryRestriction: dietaryRestriction ?? this.dietaryRestriction,
      excludedIngredients: excludedIngredients ?? this.excludedIngredients,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favoriteTags': favoriteTags,
      'recentlyCooked': recentlyCooked,
      'weeklyGoal': weeklyGoal,
      'dietaryRestriction': dietaryRestriction,
      'excludedIngredients': excludedIngredients,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      favoriteTags: (json['favoriteTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recentlyCooked: (json['recentlyCooked'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      weeklyGoal: json['weeklyGoal'] as int? ?? 7,
      dietaryRestriction: json['dietaryRestriction'] as String?,
      excludedIngredients: (json['excludedIngredients'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

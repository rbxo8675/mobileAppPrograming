import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Firestore 전용 필드
  final String? authorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final int bookmarkCount;
  final int viewCount;
  final int commentCount;
  final bool isPublic;

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
    // Firestore 필드
    this.authorId,
    this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.bookmarkCount = 0,
    this.viewCount = 0,
    this.commentCount = 0,
    this.isPublic = true,
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
    String? authorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int likeCount = 0,
    int bookmarkCount = 0,
    int viewCount = 0,
    int commentCount = 0,
    bool isPublic = true,
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
      authorId: authorId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likeCount: likeCount,
      bookmarkCount: bookmarkCount,
      viewCount: viewCount,
      commentCount: commentCount,
      isPublic: isPublic,
    );
  }

  /// Firestore DocumentSnapshot에서 Recipe 객체 생성
  factory Recipe.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    return Recipe(
      id: doc.id,
      title: data['title'] as String? ?? '',
      durationMinutes: data['durationMinutes'] as int? ?? 0,
      imagePath: data['imagePath'] as String?,
      description: data['description'] as String?,
      servings: data['servings'] as int?,
      difficulty: data['difficulty'] as String?,
      rating: (data['rating'] as num?)?.toDouble(),
      bookmarked: data['bookmarked'] as bool? ?? false,
      liked: data['liked'] as bool? ?? false,
      
      // 배열 필드
      ingredients: (data['ingredients'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      
      steps: (data['steps'] as List<dynamic>?)
          ?.map((stepData) {
            if (stepData is Map<String, dynamic>) {
              return RecipeStep(
                instruction: stepData['instruction'] as String? ?? '',
                timerMinutes: stepData['timerMinutes'] as int?,
                autoStart: stepData['autoStart'] as bool? ?? false,
              );
            }
            return RecipeStep(instruction: stepData.toString());
          })
          .toList() ?? [],
      
      tags: (data['tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      
      // Firestore 전용 필드
      authorId: data['authorId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      likeCount: data['likeCount'] as int? ?? 0,
      bookmarkCount: data['bookmarkCount'] as int? ?? 0,
      viewCount: data['viewCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      isPublic: data['isPublic'] as bool? ?? true,
    );
  }

  /// Recipe 객체를 Firestore에 저장 가능한 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'durationMinutes': durationMinutes,
      'imagePath': imagePath,
      'description': description,
      'servings': servings,
      'difficulty': difficulty,
      'rating': rating,
      'bookmarked': bookmarked,
      'liked': liked,
      
      'ingredients': ingredients,
      
      'steps': steps.map((step) => {
        'instruction': step.instruction,
        'timerMinutes': step.timerMinutes,
        'autoStart': step.autoStart,
      }).toList(),
      
      'tags': tags,
      
      // Firestore 전용 필드
      'authorId': authorId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'likeCount': likeCount,
      'bookmarkCount': bookmarkCount,
      'viewCount': viewCount,
      'commentCount': commentCount,
      'isPublic': isPublic,
    };
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
    // Firestore 필드
    String? authorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    int? bookmarkCount,
    int? viewCount,
    int? commentCount,
    bool? isPublic,
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
      // Firestore 필드
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
      viewCount: viewCount ?? this.viewCount,
      commentCount: commentCount ?? this.commentCount,
      isPublic: isPublic ?? this.isPublic,
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

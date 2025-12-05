class Bookmark {
  final String id;
  final String userId;
  final String recipeId;
  final DateTime createdAt;
  final String? collectionName;

  const Bookmark({
    required this.id,
    required this.userId,
    required this.recipeId,
    required this.createdAt,
    this.collectionName,
  });

  Bookmark copyWith({
    String? id,
    String? userId,
    String? recipeId,
    DateTime? createdAt,
    String? collectionName,
  }) {
    return Bookmark(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipeId: recipeId ?? this.recipeId,
      createdAt: createdAt ?? this.createdAt,
      collectionName: collectionName ?? this.collectionName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'recipeId': recipeId,
      'createdAt': createdAt.toIso8601String(),
      'collectionName': collectionName,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      userId: json['userId'] as String,
      recipeId: json['recipeId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      collectionName: json['collectionName'] as String?,
    );
  }
}

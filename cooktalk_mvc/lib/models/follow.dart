class Follow {
  final String id;
  final String followerId;
  final String followeeId;
  final DateTime createdAt;

  const Follow({
    required this.id,
    required this.followerId,
    required this.followeeId,
    required this.createdAt,
  });

  Follow copyWith({
    String? id,
    String? followerId,
    String? followeeId,
    DateTime? createdAt,
  }) {
    return Follow(
      id: id ?? this.id,
      followerId: followerId ?? this.followerId,
      followeeId: followeeId ?? this.followeeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'followerId': followerId,
      'followeeId': followeeId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      id: json['id'] as String,
      followerId: json['followerId'] as String,
      followeeId: json['followeeId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class FeedPost {
  final String id;
  final String userId;
  final String userName;
  final String? userImage;
  final String recipeTitle;
  final String? recipeImage;
  final String description;
  final int likes;
  final int comments;
  final String timeAgo;
  final List<String> tags;
  final bool liked;
  final bool bookmarked;
  final bool isFollowing;

  const FeedPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.recipeTitle,
    required this.description,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    this.userImage,
    this.recipeImage,
    this.tags = const [],
    this.liked = false,
    this.bookmarked = false,
    this.isFollowing = false,
  });

  FeedPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userImage,
    String? recipeTitle,
    String? recipeImage,
    String? description,
    int? likes,
    int? comments,
    String? timeAgo,
    List<String>? tags,
    bool? liked,
    bool? bookmarked,
    bool? isFollowing,
  }) {
    return FeedPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      recipeImage: recipeImage ?? this.recipeImage,
      description: description ?? this.description,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      timeAgo: timeAgo ?? this.timeAgo,
      tags: tags ?? this.tags,
      liked: liked ?? this.liked,
      bookmarked: bookmarked ?? this.bookmarked,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}


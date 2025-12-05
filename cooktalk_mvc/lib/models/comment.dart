class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userImage;
  final String text;
  final String timeAgo;
  final bool isMine;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timeAgo,
    this.userImage,
    this.isMine = false,
  });

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userImage,
    String? text,
    String? timeAgo,
    bool? isMine,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      text: text ?? this.text,
      timeAgo: timeAgo ?? this.timeAgo,
      isMine: isMine ?? this.isMine,
    );
  }
}

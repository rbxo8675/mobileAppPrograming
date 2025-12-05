import '../../models/feed_post.dart';
import '../../models/comment.dart';
import '../../core/utils/logger.dart';
import '../mock/mock_data.dart';

class FeedRepository {
  Future<List<FeedPost>> getFeedPosts() async {
    try {
      Logger.info('Fetching feed posts');
      await Future.delayed(const Duration(milliseconds: 300));

      return MockData.feedPosts.map((data) => FeedPost(
        id: data['id'] as String,
        userId: data['userId'] as String,
        userName: data['userName'] as String,
        userImage: data['userImage'] as String?,
        recipeTitle: data['recipeTitle'] as String,
        recipeImage: data['recipeImage'] as String?,
        description: data['description'] as String,
        likes: data['likes'] as int,
        comments: data['comments'] as int,
        timeAgo: data['timeAgo'] as String,
        tags: (data['tags'] as List).cast<String>(),
        isFollowing: data['isFollowing'] as bool,
      )).toList();
    } catch (e) {
      Logger.error('Failed to fetch feed posts', e);
      return [];
    }
  }

  Future<void> likePost(String postId) async {
    Logger.info('Liking post: $postId');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> bookmarkPost(String postId) async {
    Logger.info('Bookmarking post: $postId');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<List<Comment>> getComments(String postId) async {
    try {
      Logger.info('Fetching comments for post: $postId');
      await Future.delayed(const Duration(milliseconds: 300));

      // 목업 댓글 데이터
      return [
        Comment(
          id: 'c1',
          postId: postId,
          userId: 'u3',
          userName: '재현',
          text: '레시피 정말 맛있어 보여요!',
          timeAgo: '1시간 전',
        ),
        Comment(
          id: 'c2',
          postId: postId,
          userId: 'u4',
          userName: '소연',
          text: '저도 해봤는데 대박이에요',
          timeAgo: '30분 전',
        ),
        Comment(
          id: 'c3',
          postId: postId,
          userId: 'u5',
          userName: '민수',
          text: '재료 어디서 사셨어요?',
          timeAgo: '15분 전',
        ),
      ];
    } catch (e) {
      Logger.error('Failed to fetch comments', e);
      return [];
    }
  }

  Future<Comment> addComment(String postId, String text) async {
    Logger.info('Adding comment to post: $postId');
    await Future.delayed(const Duration(milliseconds: 500));

    return Comment(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: 'me',
      userName: '나',
      text: text,
      timeAgo: '방금',
      isMine: true,
    );
  }

  Future<void> updateComment(String commentId, String text) async {
    Logger.info('Updating comment: $commentId');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> deleteComment(String commentId) async {
    Logger.info('Deleting comment: $commentId');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> reportComment(String commentId) async {
    Logger.info('Reporting comment: $commentId');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> followUser(String userId) async {
    Logger.info('Following user: $userId');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> unfollowUser(String userId) async {
    Logger.info('Unfollowing user: $userId');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<List<FeedPost>> getFollowingFeed() async {
    try {
      Logger.info('Fetching following feed');
      await Future.delayed(const Duration(milliseconds: 300));

      // 팔로잉한 사용자의 게시물만 필터링
      return MockData.feedPosts
          .where((data) => data['isFollowing'] == true)
          .map((data) => FeedPost(
            id: data['id'] as String,
            userId: data['userId'] as String,
            userName: data['userName'] as String,
            userImage: data['userImage'] as String?,
            recipeTitle: data['recipeTitle'] as String,
            recipeImage: data['recipeImage'] as String?,
            description: data['description'] as String,
            likes: data['likes'] as int,
            comments: data['comments'] as int,
            timeAgo: data['timeAgo'] as String,
            tags: (data['tags'] as List).cast<String>(),
            isFollowing: true,
          ))
          .toList();
    } catch (e) {
      Logger.error('Failed to fetch following feed', e);
      return [];
    }
  }
}

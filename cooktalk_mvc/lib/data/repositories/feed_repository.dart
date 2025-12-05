import '../../models/feed_post.dart';
import '../../models/comment.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

class FeedRepository {
  Future<List<FeedPost>> getFeedPosts() async {
    try {
      Logger.info('Fetching feed posts');
      await Future.delayed(const Duration(milliseconds: AppConstants.feedLoadDelay));
      
      return [
        const FeedPost(
          id: 'p1',
          userId: 'u1',
          userName: 'Minji',
          userImage: null,
          recipeTitle: 'Kimchi Fried Rice',
          recipeImage: 'https://images.unsplash.com/photo-1516685018646-549198525c1b?q=80&w=1200&auto=format&fit=crop',
          description: '처음 해봤는데 의외로 쉽고 맛있었어요! 다음엔 베이컨도 넣어볼래요.',
          likes: 128,
          comments: 12,
          timeAgo: '2h',
          tags: ['오늘의요리', '한식', '집밥'],
          isFollowing: false,
        ),
        const FeedPost(
          id: 'p2',
          userId: 'u2',
          userName: 'Jisoo',
          recipeTitle: 'Creamy Bacon Pasta',
          recipeImage: 'https://images.unsplash.com/photo-1523986371872-9d3ba2e2f642?q=80&w=1200&auto=format&fit=crop',
          description: '크림 비율 조절이 포인트! 파마산 듬뿍 추천합니다.',
          likes: 256,
          comments: 34,
          timeAgo: '5h',
          tags: ['파스타', '크림', '저녁'],
          isFollowing: true,
        ),
      ];
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
      
      return [
        Comment(
          id: 'c1',
          postId: postId,
          userId: 'u3',
          userName: 'JaeHyun',
          text: '레시피 정말 맛있어 보여요!',
          timeAgo: '1시간 전',
        ),
        Comment(
          id: 'c2',
          postId: postId,
          userId: 'u4',
          userName: 'SoYeon',
          text: '저도 해봤는데 대박이에요',
          timeAgo: '30분 전',
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
      await Future.delayed(const Duration(milliseconds: AppConstants.feedLoadDelay));
      
      return [
        const FeedPost(
          id: 'p2',
          userId: 'u2',
          userName: 'Jisoo',
          recipeTitle: 'Creamy Bacon Pasta',
          recipeImage: 'https://images.unsplash.com/photo-1523986371872-9d3ba2e2f642?q=80&w=1200&auto=format&fit=crop',
          description: '크림 비율 조절이 포인트! 파마산 듬뿍 추천합니다.',
          likes: 256,
          comments: 34,
          timeAgo: '5h',
          tags: ['파스타', '크림', '저녁'],
          isFollowing: true,
        ),
      ];
    } catch (e) {
      Logger.error('Failed to fetch following feed', e);
      return [];
    }
  }
}

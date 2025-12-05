import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/feed_post.dart';
import '../controllers/recipe_controller.dart';
import '../views/comments_view.dart';
import 'tag_pill.dart';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({super.key, required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              child: Text(post.userName.characters.first.toUpperCase()),
            ),
            title: Text(post.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${post.timeAgo} · ${post.recipeTitle}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.tonal(
                  onPressed: () => context.read<RecipeController>().toggleFollowUser(post.userId, post.isFollowing),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(80, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(post.isFollowing ? '팔로잉' : '팔로우'),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Image
          if (post.recipeImage != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                post.recipeImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported)),
              ),
            ),
          // Body
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.description),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: -6,
                    children: [
                      ...post.tags.take(3).map((t) => TagPill(text: '#$t')),
                      if (post.tags.length > 3)
                        TagPill(text: '+${post.tags.length - 3}')
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Action(
                      icon: post.liked ? Icons.favorite : Icons.favorite_border,
                      label: '${post.likes}',
                      active: post.liked,
                      onTap: () => context.read<RecipeController>().togglePostLike(post),
                    ),
                    const SizedBox(width: 12),
                    _Action(
                      icon: Icons.mode_comment_outlined,
                      label: '${post.comments}',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CommentsView(
                              postId: post.id,
                              initialCommentCount: post.comments,
                            ),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.read<RecipeController>().togglePostBookmark(post),
                      icon: Icon(post.bookmarked ? Icons.bookmark : Icons.bookmark_border),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, this.onTap, this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : null;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}

// TagPill moved to widgets/tag_pill.dart

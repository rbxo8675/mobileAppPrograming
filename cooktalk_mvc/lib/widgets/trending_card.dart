import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../controllers/recipe_controller.dart';
import '../controllers/app_controller.dart';
import '../core/utils/snackbar_utils.dart';
import 'media_image.dart';
import 'tag_pill.dart';
import '../views/recipe_detail_view.dart';
import 'tag_pill.dart';

class TrendingCard extends StatelessWidget {
  const TrendingCard({super.key, required this.recipe, required this.rank});
  final Recipe recipe;
  final int rank; // 1-based rank

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final likes = ((recipe.rating ?? 4.0) * 120).toInt();
    final completes = ((recipe.rating ?? 4.0) * 30).toInt();
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailView(recipe: recipe),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      image: recipe.imagePath != null
                          ? null
                          : null,
                    ),
                    child: recipe.imagePath != null
                        ? (recipe.imagePath!.startsWith('http')
                            ? Hero(
                                tag: 'recipe_${recipe.id}',
                                child: Image.network(
                                  recipe.imagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.image_not_supported),
                                  ),
                                ),
                              )
                            : Hero(
                                tag: 'recipe_${recipe.id}',
                                child: Image.asset(
                                  recipe.imagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                ),
                              ))
                        : const Center(child: Icon(Icons.local_fire_department, size: 48)),
                  ),
                ),
                // Rank badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, size: 16),
                        const SizedBox(width: 6),
                        Text('#$rank',
                            style: TextStyle(
                              color: scheme.onTertiaryContainer,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
                // Recent completions avatars (fake initials)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _RecentAvatars(names: const ['A', 'B', 'C']),
                ),
                Positioned(
                  right: 12,
                  bottom: 8,
                  child: _CircleIcon(
                    icon: recipe.liked ? Icons.favorite : Icons.favorite_border,
                    onTap: () => context.read<RecipeController>().toggleLike(recipe),
                  ),
                ),
                Positioned(
                  right: 60,
                  bottom: 8,
                  child: _CircleIcon(
                    icon: recipe.bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    onTap: () async {
                      final bookmarked = await context.read<RecipeController>().toggleBookmark(recipe);
                      if (bookmarked && context.mounted) {
                        SnackBarUtils.showSuccess(
                          context,
                          '내 레시피에 저장했어요',
                          actionLabel: '보기',
                          onAction: () => context.read<AppController>().setTab(3),
                        );
                      } else if (context.mounted) {
                        SnackBarUtils.showInfo(
                          context,
                          '저장을 해제했어요',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip(icon: Icons.favorite, label: likes.toString()),
                      const SizedBox(width: 8),
                      _Chip(icon: Icons.check_circle, label: completes.toString()),
                      const SizedBox(width: 8),
                      _Chip(icon: Icons.schedule, label: '${recipe.durationMinutes}m'),
                    ],
                  ),
                ),
                if (recipe.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: -6,
                    children: [
                      ...recipe.tags.take(3).map((t) => TagPill(text: '#$t')),
                      if (recipe.tags.length > 3)
                        TagPill(text: '+${recipe.tags.length - 3}')
                    ],
                  ),
                ],
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white70,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: scheme.onSurface),
        ),
      ),
    );
  }
}

class _RecentAvatars extends StatelessWidget {
  const _RecentAvatars({required this.names});
  final List<String> names;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = 32 + (names.length - 1) * 18.0;
    return SizedBox(
      height: 32,
      width: width,
      child: Stack(
        children: [
          for (var i = 0; i < names.length; i++)
            Positioned(
              right: i * 18.0,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primary,
                child: Text(
                  names[i],
                  style: TextStyle(color: scheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


// TagPill moved to widgets/tag_pill.dart

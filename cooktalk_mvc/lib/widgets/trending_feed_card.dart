import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../controllers/recipe_controller.dart';
import '../controllers/app_controller.dart';
import '../core/utils/snackbar_utils.dart';
import '../views/recipe_detail_view.dart';
import 'tag_pill.dart';

class TrendingFeedCard extends StatelessWidget {
  const TrendingFeedCard({super.key, required this.recipe, required this.rank});
  final Recipe recipe;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final likes = ((recipe.rating ?? 4.0) * 120).toInt();
    
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
            if (recipe.imagePath != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: recipe.imagePath!.startsWith('http')
                          ? Image.network(
                              recipe.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: scheme.surfaceContainerHigh,
                                child: const Center(child: Icon(Icons.image_not_supported)),
                              ),
                            )
                          : Image.asset(
                              recipe.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: scheme.surfaceContainerHigh,
                                child: const Center(child: Icon(Icons.broken_image)),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up, size: 18, color: scheme.onPrimaryContainer),
                            const SizedBox(width: 6),
                            Text(
                              '#$rank',
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (recipe.description != null) ...[
                    Text(
                      recipe.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      _InfoChip(icon: Icons.favorite, label: '$likes', color: scheme.error),
                      const SizedBox(width: 8),
                      _InfoChip(icon: Icons.schedule, label: '${recipe.durationMinutes}분'),
                      if (recipe.difficulty != null) ...[
                        const SizedBox(width: 8),
                        _InfoChip(icon: Icons.signal_cellular_alt, label: recipe.difficulty!),
                      ],
                    ],
                  ),
                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ...recipe.tags.take(4).map((t) => TagPill(text: '#$t')),
                        if (recipe.tags.length > 4)
                          TagPill(text: '+${recipe.tags.length - 4}')
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailView(recipe: recipe),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('요리 시작'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: Icon(recipe.liked ? Icons.favorite : Icons.favorite_border),
                        onPressed: () => context.read<RecipeController>().toggleLike(recipe),
                      ),
                      IconButton.filledTonal(
                        icon: Icon(recipe.bookmarked ? Icons.bookmark : Icons.bookmark_border),
                        onPressed: () async {
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

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
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

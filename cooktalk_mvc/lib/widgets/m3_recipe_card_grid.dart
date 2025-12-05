import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../controllers/recipe_controller.dart';
import '../controllers/app_controller.dart';
import '../core/utils/snackbar_utils.dart';
import 'circle_icon_button.dart';
import 'media_image.dart';
import 'tag_pill.dart';
import '../views/recipe_detail_view.dart';

class M3RecipeCardGrid extends StatelessWidget {
  const M3RecipeCardGrid({super.key, required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailView(recipe: recipe)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Hero(
                    tag: 'recipe_${recipe.id}',
                    child: MediaImage(path: recipe.imagePath, fit: BoxFit.cover),
                  ),
                ),
                if (recipe.difficulty != null)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _DifficultyBadge(text: recipe.difficulty!),
                  ),
                if (recipe.rating != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${recipe.rating}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: CircleIconButton(
                    icon: recipe.liked ? Icons.favorite : Icons.favorite_border,
                    active: recipe.liked,
                    onTap: () => context.read<RecipeController>().toggleLike(recipe),
                    tooltip: 'Like',
                  ),
                ),
                Positioned(
                  right: 60,
                  bottom: 12,
                  child: CircleIconButton(
                    icon: recipe.bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    active: recipe.bookmarked,
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
                    tooltip: 'Bookmark',
                  ),
                ),
              ],
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
                  if (recipe.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      recipe.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${recipe.durationMinutes} min',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (recipe.servings != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.people_alt, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${recipe.servings} servings',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 28,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...recipe.tags.take(3).map((t) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: TagPill(text: '#$t'),
                                )),
                            if (recipe.tags.length > 3) const TagPill(text: '...')
                          ],
                        ),
                      ),
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

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _difficultyColors(context, text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_difficultyIcon(text), size: 14, color: fg),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

(Color, Color) _difficultyColors(BuildContext context, String text) {
  final s = Theme.of(context).colorScheme;
  final lower = text.toLowerCase();
  if (lower.contains('easy') || text.contains('쉬움')) {
    return (s.secondaryContainer, s.onSecondaryContainer);
  }
  if (lower.contains('medium') || text.contains('보통')) {
    return (s.tertiaryContainer, s.onTertiaryContainer);
  }
  if (lower.contains('hard') || text.contains('어려움')) {
    return (s.errorContainer, s.onErrorContainer);
  }
  return (s.secondaryContainer, s.onSecondaryContainer);
}

IconData _difficultyIcon(String text) {
  final lower = text.toLowerCase();
  if (lower.contains('easy') || text.contains('쉬움')) return Icons.check_circle;
  if (lower.contains('medium') || text.contains('보통')) return Icons.tune;
  if (lower.contains('hard') || text.contains('어려움')) return Icons.whatshot;
  return Icons.check_circle;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../controllers/recipe_controller.dart';
import '../controllers/app_controller.dart';
import '../core/utils/snackbar_utils.dart';
import 'media_image.dart';
import 'tag_pill.dart';
import '../views/recipe_detail_view.dart';

class RecipeListCard extends StatelessWidget {
  const RecipeListCard({super.key, required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailView(recipe: recipe)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              SizedBox(
                width: 110,
                height: 110,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: scheme.surfaceContainerHigh),
                    child: MediaImage(path: recipe.imagePath, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 0,
                          children: [
                            IconButton(
                              icon: Icon(
                                recipe.liked ? Icons.favorite : Icons.favorite_border,
                              ),
                              color: recipe.liked ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                              padding: const EdgeInsets.all(4.0),
                              onPressed: () {
                                context.read<RecipeController>().toggleLike(recipe);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                recipe.bookmarked ? Icons.bookmark : Icons.bookmark_border,
                              ),
                              padding: const EdgeInsets.all(4.0),
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
                    if (recipe.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        recipe.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16),
                        const SizedBox(width: 4),
                        Text('${recipe.durationMinutes} min', style: Theme.of(context).textTheme.bodySmall),
                        if (recipe.servings != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.people_alt, size: 16),
                          const SizedBox(width: 4),
                          Text('${recipe.servings} servings', style: Theme.of(context).textTheme.bodySmall),
                        ],
                        if (recipe.rating != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text('${recipe.rating}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                    if (recipe.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: -6,
                        children: [
                          ...recipe.tags.take(3).map((t) => TagPill(text: '#$t')),
                          if (recipe.tags.length > 3) TagPill(text: '+${recipe.tags.length - 3}')
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../controllers/recipe_controller.dart';
import 'media_image.dart';
import '../views/recipe_detail_view.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailView(recipe: recipe),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MediaImage(path: recipe.imagePath, fit: BoxFit.cover),
                  if (recipe.difficulty != null)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(recipe.difficulty!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recipe.difficulty!,
                          style: TextStyle(
                            color: _getDifficultyTextColor(recipe.difficulty!),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.durationMinutes}분',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (recipe.servings != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.people_alt_rounded,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.servings}인분',
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (recipe.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: recipe.tags.take(2).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      recipe.liked 
                          ? Icons.favorite 
                          : Icons.favorite_border,
                    ),
                    color: recipe.liked ? Colors.red : scheme.onSurfaceVariant,
                    iconSize: 22,
                    onPressed: () => context
                        .read<RecipeController>()
                        .toggleLike(recipe),
                  ),
                  IconButton(
                    icon: Icon(
                      recipe.bookmarked 
                          ? Icons.bookmark 
                          : Icons.bookmark_border,
                    ),
                    color: recipe.bookmarked 
                        ? scheme.primary 
                        : scheme.onSurfaceVariant,
                    iconSize: 22,
                    onPressed: () => context
                        .read<RecipeController>()
                        .toggleBookmark(recipe),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    if (difficulty.contains('쉬움')) return const Color(0xFFDCFCE7);
    if (difficulty.contains('보통')) return const Color(0xFFFEF3C7);
    if (difficulty.contains('어려움')) return const Color(0xFFFEE2E2);
    return const Color(0xFFE5E7EB);
  }

  Color _getDifficultyTextColor(String difficulty) {
    if (difficulty.contains('쉬움')) return const Color(0xFF166534);
    if (difficulty.contains('보통')) return const Color(0xFF92400E);
    if (difficulty.contains('어려움')) return const Color(0xFF991B1B);
    return const Color(0xFF374151);
  }
}

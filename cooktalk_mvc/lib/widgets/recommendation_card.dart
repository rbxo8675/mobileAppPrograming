import 'package:flutter/material.dart';
import '../models/recipe.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({super.key, required this.recipe, this.onTap});
  final Recipe recipe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: scheme.surfaceContainerHigh),
                  child: _Image(imagePath: recipe.imagePath),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14),
                        const SizedBox(width: 4),
                        Text('${recipe.durationMinutes}분',
                            style: Theme.of(context).textTheme.bodySmall),
                        if (recipe.rating != null) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text('${recipe.rating}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
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

class _Image extends StatelessWidget {
  const _Image({required this.imagePath});
  final String? imagePath;
  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return const Center(child: Icon(Icons.restaurant_menu, size: 36));
    }
    if (imagePath!.startsWith('http')) {
      return Image.network(
        imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported)),
      );
    }
    return Image.asset(
      imagePath!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
    );
  }
}

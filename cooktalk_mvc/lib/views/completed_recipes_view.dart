import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cooking_assistant_controller.dart';
import '../controllers/recipe_controller.dart';
import '../widgets/recipe_list_card.dart';
import '../widgets/empty_state.dart';
import '../models/cooking_session.dart';

enum CompletedFilter { recent, duration, difficulty }

class CompletedRecipesView extends StatefulWidget {
  const CompletedRecipesView({super.key});

  @override
  State<CompletedRecipesView> createState() => _CompletedRecipesViewState();
}

class _CompletedRecipesViewState extends State<CompletedRecipesView> {
  CompletedFilter _filter = CompletedFilter.recent;

  @override
  Widget build(BuildContext context) {
    final cookingController = context.watch<CookingAssistantController>();
    final recipeController = context.watch<RecipeController>();
    
    var sessions = cookingController.completedSessions;
    
    switch (_filter) {
      case CompletedFilter.recent:
        sessions.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
        break;
      case CompletedFilter.duration:
        sessions.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case CompletedFilter.difficulty:
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('완료한 요리'),
        actions: [
          PopupMenuButton<CompletedFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() => _filter = filter);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CompletedFilter.recent,
                child: Text('최근순'),
              ),
              const PopupMenuItem(
                value: CompletedFilter.duration,
                child: Text('소요시간순'),
              ),
            ],
          ),
        ],
      ),
      body: sessions.isEmpty
          ? const Center(
              child: EmptyState(
                message: '완료한 요리가 없습니다',
                subtitle: '레시피를 따라 요리하고\n기록을 남겨보세요',
                icon: Icons.restaurant,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final recipe = recipeController.getById(session.recipeId);
                
                if (recipe == null) {
                  return const SizedBox.shrink();
                }
                
                return Column(
                  children: [
                    _CompletedRecipeCard(
                      session: session,
                      recipe: recipe,
                    ),
                    if (index < sessions.length - 1)
                      const SizedBox(height: 12),
                  ],
                );
              },
            ),
    );
  }
}

class _CompletedRecipeCard extends StatelessWidget {
  const _CompletedRecipeCard({
    required this.session,
    required this.recipe,
  });

  final CookingSession session;
  final dynamic recipe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = session.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    String durationText = '';
    if (hours > 0) durationText += '$hours시간 ';
    durationText += '$minutes분';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDate(session.completedAt!),
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (session.rating != null) ...[
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${session.rating}/5'),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recipe.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '소요시간: $durationText',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            if (session.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                session.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (session.photoPath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  session.photoPath!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: scheme.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return '오늘';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    
    return '${date.month}/${date.day}';
  }
}

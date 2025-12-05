import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../widgets/tag_pill.dart';
import '../controllers/recipe_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cooking_assistant_controller.dart';
import 'package:cooktalk_mvc/widgets/media_image.dart';
import 'cooking_assistant_view.dart';
import 'smart_cooking_guide_view.dart';
import 'recipe_form_view.dart';

class RecipeDetailView extends StatelessWidget {
  const RecipeDetailView({super.key, required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isOwner = authController.currentUser != null && 
                   recipe.authorId == authController.currentUser!.uid;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            systemOverlayStyle: SystemUiOverlayStyle.light,
            pinned: true,
            expandedHeight: 260,
            backgroundColor: Colors.black87,
            iconTheme: const IconThemeData(color: Colors.white),
            actionsIconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: isOwner ? [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeFormView(recipe: recipe),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Recipe'),
                      content: const Text('Are you sure you want to delete this recipe?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true && context.mounted) {
                    await context.read<RecipeController>().deleteRecipe(recipe.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ] : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'recipe_',
                    child: MediaImage(path: recipe.imagePath, fit: BoxFit.cover),
                  ),
                  // 상단 그라데이션 (아이콘 보호)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 18),
                      const SizedBox(width: 6),
                      Text('${recipe.durationMinutes} min'),
                      if (recipe.servings != null) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.people_alt, size: 18),
                        const SizedBox(width: 6),
                        Text('${recipe.servings} servings'),
                      ],
                    ],
                  ),
                  if (recipe.description != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      recipe.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (recipe.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: -6,
                      children: [
                        ...recipe.tags.take(5).map((t) => TagPill(text: '#$t')),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final ing in recipe.ingredients)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check, size: 16),
                                const SizedBox(width: 6),
                                Expanded(child: Text(ing)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Steps', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      for (var i = 0; i < recipe.steps.length; i++)
                        _CardContainer(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(radius: 12, child: Text('${i + 1}')),
                              const SizedBox(width: 10),
                              Expanded(child: Text(recipe.steps[i].instruction)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SmartCookingGuideView(recipe: recipe),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('요리 가이드 시작', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (newContext) => ChangeNotifierProvider.value(
                                  value: context.read<CookingAssistantController>(),
                                  child: CookingAssistantView(recipe: recipe),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.psychology),
                          label: const Text('AI 도우미'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<RecipeController>().markCompleted(recipe);
                            Navigator.of(context).maybePop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('완료했습니다!')),
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('완료'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.child, this.margin});
  final Widget child; final EdgeInsets? margin;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}


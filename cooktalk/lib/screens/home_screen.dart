import 'package:cooktalk/models/recipe.dart';
import 'package:cooktalk/providers/app_settings_provider.dart';
import 'package:cooktalk/providers/session_provider.dart';
import 'package:cooktalk/screens/cooking_session_screen.dart';
import 'package:cooktalk/screens/recipe_detail_screen.dart';
import 'package:cooktalk/screens/my_page_screen.dart';
import 'package:cooktalk/screens/settings_screen.dart';
import 'package:cooktalk/services/recipe_repository.dart';
import 'package:cooktalk/providers/favorites_provider.dart';
import 'package:cooktalk/screens/recipe_upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecipeRepository _recipeRepository = RecipeRepository();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('쿡톡'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyPageScreen()),
              );
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              setState(() {}); // Refresh list after returning from settings
            },
          ),
        ],
      ),
      body: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) => FutureBuilder<List<Recipe>>(
          future: _recipeRepository.getAllRecipes(useFirestore: settings.useFirestore),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('오류: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('레시피가 없습니다.'));
            } else {
              final recipes = snapshot.data!;
              final filtered = (_query.trim().isEmpty)
                  ? recipes
                  : recipes
                      .where((r) => r.title.toLowerCase().contains(_query.toLowerCase()))
                      .toList();
              final recommended = recipes.take(5).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: '요리 검색 (예: 김치찌개)',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: '레시피 업로드',
                          icon: const Icon(Icons.upload_file),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RecipeUploadScreen()),
                            );
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('추천 레시피', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (context, index) {
                        final recipe = recommended[index];
                        return _RecipeCardCompact(
                          recipe: recipe,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailScreen(recipe: recipe),
                              ),
                            );
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: recommended.length,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('전체 레시피', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  ListView.builder(
                    itemCount: filtered.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final recipe = filtered[index];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          leading: Builder(
                            builder: (context) {
                              final favs = context.watch<FavoritesProvider>();
                              final isFav = favs.isFavorite(recipe.id);
                              return IconButton(
                                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.pink),
                                onPressed: () => favs.toggle(recipe.id),
                                tooltip: isFav ? '즐겨찾기 해제' : '즐겨찾기 추가',
                              );
                            },
                          ),
                          title: Text(recipe.title),
                          subtitle: Text('${recipe.steps.length} 단계'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailScreen(recipe: recipe),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class _RecipeCardCompact extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  const _RecipeCardCompact({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(recipe.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text('${recipe.steps.length} 단계', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

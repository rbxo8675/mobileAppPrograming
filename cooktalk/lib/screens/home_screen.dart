import 'package:cooktalk/models/recipe.dart';
import 'package:cooktalk/providers/session_provider.dart';
import 'package:cooktalk/screens/cooking_session_screen.dart';
import 'package:cooktalk/services/recipe_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Recipe>> _recipesFuture;
  final RecipeRepository _recipeRepository = RecipeRepository();

  @override
  void initState() {
    super.initState();
    _recipesFuture = _recipeRepository.getRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('쿡톡'),
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('레시피가 없습니다.'));
          } else {
            final recipes = snapshot.data!;
            return ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(recipe.title),
                    subtitle: Text('${recipe.steps.length} 단계'),
                    onTap: () {
                      Provider.of<SessionProvider>(context, listen: false)
                          .setRecipe(recipe);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CookingSessionScreen(),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
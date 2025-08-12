import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cooktalk/models/recipe.dart';
import 'package:cooktalk/services/recipe_repository.dart';
import 'package:cooktalk/screens/cooking_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late RecipeRepository _repository;
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = RecipeRepository();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recipes = await _repository.getRecipes();
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('레시피를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _searchRecipes(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    try {
      final recipes = await _repository.searchRecipes(query);
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startCookingSession(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CookingSessionScreen(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CookTalk'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecipes,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '레시피 검색...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchRecipes,
            ),
          ),
          
          // 레시피 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recipes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              '레시피가 없습니다',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _recipes[index];
                          return _buildRecipeCard(recipe);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    final totalTime = _repository.calculateTotalTime(recipe);
    final difficulty = _repository.calculateDifficulty(recipe);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      child: InkWell(
        onTap: () => _startCookingSession(recipe),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(difficulty),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      difficulty,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.servingsBase}인분',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(totalTime),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.format_list_numbered, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.steps.length}단계',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '재료: ${recipe.ingredients.take(3).map((i) => i.name).join(', ')}${recipe.ingredients.length > 3 ? '...' : ''}',
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '쉬움':
        return Colors.green;
      case '보통':
        return Colors.orange;
      case '어려움':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}초';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}분';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}시간 ${minutes}분';
    }
  }
}

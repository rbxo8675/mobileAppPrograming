import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/recipe_controller.dart';
import '../data/repositories/search_repository.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final SearchRepository _searchRepo = SearchRepository();
  
  List<Recipe> _searchResults = [];
  List<String> _selectedIngredients = [];
  List<String> _selectedTags = [];
  int? _maxTime;
  String? _selectedDifficulty;
  
  bool _showFilters = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _performSearch() {
    final controller = context.read<RecipeController>();
    final allRecipes = [
      ...controller.explore,
      ...controller.trending,
      ...controller.myRecipes,
    ];
    
    setState(() {
      _searchResults = _searchRepo.combineFilters(
        recipes: allRecipes,
        textQuery: _searchController.text,
        ingredients: _selectedIngredients.isEmpty ? null : _selectedIngredients,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
        maxTime: _maxTime,
        difficulty: _selectedDifficulty,
      );
    });
  }
  
  void _toggleIngredient(String ingredient) {
    setState(() {
      if (_selectedIngredients.contains(ingredient)) {
        _selectedIngredients.remove(ingredient);
      } else {
        _selectedIngredients.add(ingredient);
      }
    });
    _performSearch();
  }
  
  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    _performSearch();
  }
  
  void _clearFilters() {
    setState(() {
      _selectedIngredients.clear();
      _selectedTags.clear();
      _maxTime = null;
      _selectedDifficulty = null;
      _searchController.clear();
    });
    _performSearch();
  }
  
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = context.watch<RecipeController>();
    final allRecipes = [
      ...controller.explore,
      ...controller.trending,
      ...controller.myRecipes,
    ];
    
    final popularTags = _searchRepo.getPopularTags(allRecipes);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('레시피 검색'),
        actions: [
          if (_selectedIngredients.isNotEmpty || 
              _selectedTags.isNotEmpty || 
              _maxTime != null ||
              _selectedDifficulty != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: '필터 초기화',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(scheme),
          _buildFilterChips(scheme, popularTags),
          if (_showFilters)
            _buildAdvancedFilters(scheme),
          Expanded(
            child: _buildResults(scheme),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '레시피 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_off),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: '상세 필터',
            style: IconButton.styleFrom(
              backgroundColor: scheme.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChips(ColorScheme scheme, List<String> popularTags) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: '계란',
            selected: _selectedIngredients.contains('계란'),
            onTap: () => _toggleIngredient('계란'),
          ),
          _FilterChip(
            label: '밥',
            selected: _selectedIngredients.contains('밥'),
            onTap: () => _toggleIngredient('밥'),
          ),
          _FilterChip(
            label: '김치',
            selected: _selectedIngredients.contains('김치'),
            onTap: () => _toggleIngredient('김치'),
          ),
          _FilterChip(
            label: '면',
            selected: _selectedIngredients.contains('면'),
            onTap: () => _toggleIngredient('면'),
          ),
          const SizedBox(width: 8),
          Container(width: 1, color: scheme.outlineVariant),
          const SizedBox(width: 8),
          ...popularTags.take(5).map((tag) => _FilterChip(
            label: tag,
            selected: _selectedTags.contains(tag),
            onTap: () => _toggleTag(tag),
          )),
        ],
      ),
    );
  }
  
  Widget _buildAdvancedFilters(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상세 필터',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeFilter(scheme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDifficultyFilter(scheme),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeFilter(ColorScheme scheme) {
    return DropdownButtonFormField<int>(
      value: _maxTime,
      decoration: InputDecoration(
        labelText: '조리 시간',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('전체')),
        const DropdownMenuItem(value: 10, child: Text('10분 이하')),
        const DropdownMenuItem(value: 20, child: Text('20분 이하')),
        const DropdownMenuItem(value: 30, child: Text('30분 이하')),
      ],
      onChanged: (value) {
        setState(() => _maxTime = value);
        _performSearch();
      },
    );
  }
  
  Widget _buildDifficultyFilter(ColorScheme scheme) {
    return DropdownButtonFormField<String>(
      value: _selectedDifficulty,
      decoration: InputDecoration(
        labelText: '난이도',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('전체')),
        DropdownMenuItem(value: '쉬움', child: Text('쉬움')),
        DropdownMenuItem(value: '보통', child: Text('보통')),
        DropdownMenuItem(value: '어려움', child: Text('어려움')),
      ],
      onChanged: (value) {
        setState(() => _selectedDifficulty = value);
        _performSearch();
      },
    );
  }
  
  Widget _buildResults(ColorScheme scheme) {
    if (_searchController.text.isEmpty && 
        _selectedIngredients.isEmpty && 
        _selectedTags.isEmpty &&
        _maxTime == null &&
        _selectedDifficulty == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: scheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '레시피를 검색해보세요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '재료나 요리 이름으로 검색하거나\n필터를 사용해보세요',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: scheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '다른 검색어나 필터를 시도해보세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return RecipeCard(recipe: _searchResults[index]);
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        labelStyle: TextStyle(
          color: selected 
              ? scheme.onPrimaryContainer 
              : scheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

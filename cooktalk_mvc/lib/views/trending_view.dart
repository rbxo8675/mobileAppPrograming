import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/recipe_controller.dart';
import '../widgets/trending_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_divider.dart';

class TrendingView extends StatelessWidget {
  const TrendingView({super.key});

  @override
  Widget build(BuildContext context) {
    final rc = context.watch<RecipeController>();
    return RefreshIndicator(
      onRefresh: rc.loadTrending,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Trending', style: Theme.of(context).textTheme.titleLarge),
          const SectionDivider(),
          if (rc.loadingTrending)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (rc.trending.isEmpty)
            const EmptyState(message: 'No trending recipes yet')
          else GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 360,
            ),
            itemCount: rc.trending.length,
            itemBuilder: (_, i) => TrendingCard(recipe: rc.trending[i], rank: i + 1),
          ),
        ],
      ),
    );
  }
  // switched to GridView.builder above
}

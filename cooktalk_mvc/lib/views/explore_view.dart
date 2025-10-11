import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/recipe_controller.dart';
import 'package:cooktalk_mvc/widgets/m3_recipe_card_grid.dart';
import 'package:cooktalk_mvc/widgets/recipe_list_card.dart';
import '../widgets/cooktalk_welcome.dart';
import '../widgets/home_stats.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_divider.dart';

enum ExploreLayout { auto, list, grid }

class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  ExploreLayout layout = ExploreLayout.auto;

  @override
  Widget build(BuildContext context) {
    final rc = context.watch<RecipeController>();
    final username = '요리사';
    final todayCount = rc.explore.length;

    return RefreshIndicator(
      onRefresh: rc.loadExplore,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          CookTalkWelcome(
            userName: username,
            todayRecipeCount: todayCount,
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HomeStats(
              completedCount: rc.completedCount,
              weeklyGoal: 7,
              cookedToday: false,
            ),
          ),

          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '오늘의 추천',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: rc.loadingExplore
                ? const Center(child: CircularProgressIndicator())
                : rc.explore.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: EmptyState(message: '추천 레시피가 없습니다'),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: rc.explore.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => SizedBox(
                          width: MediaQuery.of(context).size.width * 0.85,
                          child: RecommendationCard(recipe: rc.explore[i]),
                        ),
                      ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '추천 레시피 더 보기',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SectionDivider(),
          ),

          if (rc.loadingExplore)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (rc.explore.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: EmptyState(message: '추천 레시피가 없습니다'),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: rc.explore.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => RecipeListCard(recipe: rc.explore[i]),
            ),
            
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

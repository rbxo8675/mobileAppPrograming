import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/recipe_controller.dart';
import 'package:cooktalk_mvc/widgets/m3_recipe_card_grid.dart';
import 'package:cooktalk_mvc/widgets/recipe_list_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_divider.dart';
import '../widgets/skeleton_loader.dart';
import 'add_recipe_sheet.dart';

enum RecipesTab { myRecipes, saved }
enum ExploreLayout { auto, list, grid }

class MyRecipesView extends StatefulWidget {
  const MyRecipesView({super.key});

  @override
  State<MyRecipesView> createState() => _MyRecipesViewState();
}

class _MyRecipesViewState extends State<MyRecipesView> {
  RecipesTab tab = RecipesTab.myRecipes;
  ExploreLayout layout = ExploreLayout.auto;

  @override
  Widget build(BuildContext context) {
    final rc = context.watch<RecipeController>();

    return RefreshIndicator(
      onRefresh: () async {
        if (tab == RecipesTab.myRecipes) {
          await rc.loadMyRecipes();
        } else {
          await rc.loadSavedRecipes();
        }
      },
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Spacer(),
            SegmentedButton<RecipesTab>(
              segments: const [
                ButtonSegment(value: RecipesTab.myRecipes, icon: Icon(Icons.kitchen), label: Text('내 레시피')),
                ButtonSegment(value: RecipesTab.saved, icon: Icon(Icons.bookmark), label: Text('저장됨')),
              ],
              selected: {tab},
              onSelectionChanged: (s) => setState(() => tab = s.first),
            ),
          ],
        ),

        const SizedBox(height: 8),
        const SectionDivider(),

        Row(
          children: [
            const Spacer(),
            ToggleButtons(
              isSelected: [
                layout == ExploreLayout.list,
                layout == ExploreLayout.grid,
              ],
              onPressed: (i) {
                setState(() {
                  layout = [ExploreLayout.list, ExploreLayout.grid, ExploreLayout.auto][i];
                });
              },
              borderRadius: BorderRadius.circular(20),
              constraints: const BoxConstraints(minHeight: 36, minWidth: 40),
              children: const [
                Tooltip(message: '리스트', child: Icon(Icons.view_list)),
                Tooltip(message: '그리드', child: Icon(Icons.grid_view)),
              ],
            ),
          ],
        ),

        if (tab == RecipesTab.myRecipes) ...[
          const SizedBox(height: 8),
          if (rc.loadingMyRecipes)
            ...() {
              final useGrid = layout == ExploreLayout.grid ||
                  (layout == ExploreLayout.auto);
              if (useGrid) {
                return [const SkeletonGrid(itemCount: 4)];
              } else {
                return [const SkeletonList(itemCount: 3)];
              }
            }()
          else if (rc.myRecipes.isEmpty)
            EmptyState(
              message: '작성한 레시피가 없습니다',
              subtitle: '나만의 레시피를 만들어보세요',
              icon: Icons.menu_book,
              actionLabel: '+ 레시피 추가하기',
              onAction: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const AddRecipeSheet(),
                );
              },
            )
          else
            ...() {
              final useGrid = layout == ExploreLayout.grid ||
                  (layout == ExploreLayout.auto && rc.myRecipes.length >= 4);
              if (useGrid) {
                return [
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 360,
                    ),
                    itemCount: rc.myRecipes.length,
                    itemBuilder: (_, i) => M3RecipeCardGrid(recipe: rc.myRecipes[i]),
                  ),
                ];
              } else {
                return [
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: rc.myRecipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => RecipeListCard(recipe: rc.myRecipes[i]),
                  ),
                ];
              }
            }(),
        ] else ...[
          // Saved Recipes Tab
          const SizedBox(height: 8),
          if (rc.loadingSavedRecipes)
            ...() {
              final useGrid = layout == ExploreLayout.grid ||
                  (layout == ExploreLayout.auto);
              if (useGrid) {
                return [const SkeletonGrid(itemCount: 4)];
              } else {
                return [const SkeletonList(itemCount: 3)];
              }
            }()
          else if (rc.savedRecipes.isEmpty)
            EmptyState(
              message: '저장된 레시피가 없습니다',
              subtitle: '마음에 드는 레시피를 저장해보세요',
              icon: Icons.bookmark_border,
              actionLabel: '레시피 둘러보기',
              onAction: () {
                 // TODO: Navigate to explore tab or similar action
              },
            )
          else
            ...() {
              final useGrid = layout == ExploreLayout.grid ||
                  (layout == ExploreLayout.auto && rc.savedRecipes.length >= 4);
              if (useGrid) {
                return [
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 360,
                    ),
                    itemCount: rc.savedRecipes.length,
                    itemBuilder: (_, i) => M3RecipeCardGrid(recipe: rc.savedRecipes[i]),
                  ),
                ];
              } else {
                return [
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: rc.savedRecipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => RecipeListCard(recipe: rc.savedRecipes[i]),
                  ),
                ];
              }
            }(),
        ],
      ],
      ),
    );
  }
}


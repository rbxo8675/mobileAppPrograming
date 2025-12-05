import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../widgets/material_bottom_nav.dart';
import '../core/utils/context_extensions.dart';

import 'explore_view.dart';
import 'trending_view.dart';
import 'feed_view.dart';
import 'keep_alive.dart';
import '../widgets/fab_speed_dial.dart';
import 'recipe_form_view.dart';
import 'youtube_extract_view.dart';
import 'my_recipes_view.dart';
import 'profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Selector<AppController, int>(
          selector: (_, app) => app.tabIndex,
          builder: (_, tabIndex, __) {
            return Text(_getTabTitle(tabIndex));
          },
        ),
        centerTitle: false,
      ),
      body: Selector<AppController, int>(
        selector: (_, app) => app.tabIndex,
        builder: (_, tabIndex, __) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(animation);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slide,
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(tabIndex),
              child: KeepAliveWrapper(
                child: _buildBody(tabIndex),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Selector<AppController, int>(
        selector: (_, app) => app.tabIndex,
        builder: (_, tabIndex, __) {
          return MaterialBottomNav(
            activeIndex: tabIndex,
            onChanged: context.app.setTab,
            showActiveBadge: true,
          );
        },
      ),
      floatingActionButton: Selector<AppController, bool>(
        selector: (_, app) => app.tabIndex == 3,
        builder: (_, isRecipeTab, __) {
          if (!isRecipeTab) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () {
              showFabMenu(
                context,
                onAddManual: () => context.push(const RecipeFormView()),
                onExtractYoutube: () =>
                    context.push(const YoutubeExtractView()),
              );
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  String _getTabTitle(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'CookTalk';
      case 1:
        return 'Trending';
      case 2:
        return 'Feed';
      case 3:
        return 'My Recipes';
      case 4:
        return 'Profile';
      default:
        return 'CookTalk';
    }
  }

  Widget _buildBody(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return const ExploreView();
      case 1:
        return const TrendingView();
      case 2:
        return const FeedView();
      case 3:
        return const MyRecipesView();
      case 4:
        return const ProfileView();
      default:
        return const ExploreView();
    }
  }
}

class _YouTubeImportDialog extends StatefulWidget {
  const _YouTubeImportDialog();

  @override
  State<_YouTubeImportDialog> createState() => _YouTubeImportDialogState();
}

class _YouTubeImportDialogState extends State<_YouTubeImportDialog> {
  final TextEditingController ctrl = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import from YouTube'),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(
          hintText: 'https://www.youtube.com/watch?v=...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: loading
              ? null
              : () async {
                  if (ctrl.text.isEmpty) return;

                  setState(() => loading = true);

                  await context.recipes.importFromYouTube(ctrl.text);

                  if (!context.mounted) return;

                  setState(() => loading = false);
                  context.pop();
                  context.showSuccessSnackBar('Imported!');
                },
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Import'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }
}

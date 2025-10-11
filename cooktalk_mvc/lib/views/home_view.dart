import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_controller.dart';
import '../controllers/recipe_controller.dart' as controllers;
import '../widgets/material_bottom_nav.dart';

import 'explore_view.dart';
import 'trending_view.dart';
import 'feed_view.dart';
import 'keep_alive.dart';
import '../widgets/fab_speed_dial.dart';
import 'recipe_form_view.dart';
import 'youtube_extract_view.dart';
import 'my_recipes_view.dart';
// import 'settings_view.dart';
import 'profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {

  // Tabs are rendered by MaterialBottomNav

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();

    Widget body;
    switch (app.tabIndex) {
      case 0:
        body = const ExploreView();
        break;
      case 1:
        body = const TrendingView();
        break;
      case 2:
        body = const FeedView();
        break;
      case 3:
        body = const MyRecipesView();
        break;
      case 4:
        body = const ProfileView();
        break;
      default:
        body = const ExploreView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(() {
          switch (app.tabIndex) {
            case 0:
              return 'CookTalk'; // 홈만 CookTalk
            case 1:
              return '인기';
            case 2:
              return '피드';
            case 3:
              return '레시피';
            case 4:
              return '프로필';
            default:
              return 'CookTalk';
          }
        }()),
        centerTitle: false,
      ),
      body: AnimatedSwitcher(
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
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(app.tabIndex),
          child: KeepAliveWrapper(child: body),
        ),
      ),
      bottomNavigationBar: MaterialBottomNav(
        activeIndex: app.tabIndex,
        onChanged: app.setTab,
        showActiveBadge: true,
      ),
      floatingActionButton: app.tabIndex == 3
          ? FloatingActionButton(
              onPressed: () {
                showFabMenu(
                  context,
                  onAddManual: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const RecipeFormView())),
                  onExtractYoutube: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const YoutubeExtractView())),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _YouTubeImportDialog extends StatefulWidget {
  const _YouTubeImportDialog();

  @override
  State<_YouTubeImportDialog> createState() => _YouTubeImportDialogState();
}

class _YouTubeImportDialogState extends State<_YouTubeImportDialog> {
  final ctrl = TextEditingController();
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: loading
              ? null
              : () async {
                  if (ctrl.text.isEmpty) return;
                  setState(() => loading = true);
                  await context
                      .read<controllers.RecipeController>()
                      .importFromYouTube(ctrl.text);
                  if (mounted) {
                    setState(() => loading = false);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Imported!')),
                    );
                  }
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
}

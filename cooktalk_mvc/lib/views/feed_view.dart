import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/recipe_controller.dart';
import '../widgets/feed_post_card.dart';
import '../widgets/empty_state.dart';

enum FeedFilter { all, following }

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  FeedFilter filter = FeedFilter.all;

  @override
  Widget build(BuildContext context) {
    final rc = context.watch<RecipeController>();
    return RefreshIndicator(
      onRefresh: () async {
        if (filter == FeedFilter.all) {
          await rc.loadFeed();
        } else {
          await rc.loadFollowingFeed();
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text('Social Feed', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              SegmentedButton<FeedFilter>(
                segments: const [
                  ButtonSegment(value: FeedFilter.all, label: Text('전체')),
                  ButtonSegment(value: FeedFilter.following, label: Text('팔로잉')),
                ],
                selected: {filter},
                onSelectionChanged: (selected) {
                  setState(() => filter = selected.first);
                  if (filter == FeedFilter.following) {
                    rc.loadFollowingFeed();
                  } else {
                    rc.loadFeed();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rc.loadingFeed)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (rc.feed.isEmpty)
            EmptyState(
              message: filter == FeedFilter.following ? '팔로우한 사용자가 없습니다' : '아직 피드가 없어요',
              subtitle: filter == FeedFilter.following ? '다른 사용자를 팔로우해보세요' : null,
            )
          else ...rc.feed.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FeedPostCard(post: p),
                ),
              ),
        ],
      ),
    );
  }
}


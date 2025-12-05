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
import '../core/utils/context_extensions.dart';

/// 🏠 ExploreView - 탐색 화면 (홈 탭)
/// 
/// ### 주요 기능:
/// 1. **환영 메시지**: 사용자 이름과 오늘의 레시피 개수 표시
/// 2. **이번주 목표**: 주간 요리 목표 및 달성률 (주 5회)
/// 3. **오늘의 추천**: 추천 레시피 리스트 (초기 2개 표시)
/// 4. **더보기 기능**: + 버튼으로 2개씩 추가 로딩
/// 
/// ### UI 구조:
/// ```
/// 환영 메시지
/// ↓
/// 이번주 목표 (주 5회)
/// ↓
/// 오늘의 추천
/// ├─ 레시피 1
/// ├─ 레시피 2
/// ↓
/// [+ 더보기 버튼]
/// ├─ 레시피 3, 4 (클릭 시)
/// ├─ 레시피 5, 6 (다시 클릭 시)
/// ...
/// ↓
/// "모든 레시피 확인" (완료 시)
/// ```
/// 
/// ### 성능 최적화:
/// - Selector 패턴으로 필요한 데이터만 감시
/// - Consumer로 로딩 상태 관리
/// - 점진적 로딩으로 초기 렌더링 속도 향상
enum ExploreLayout { auto, list, grid }

class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  ExploreLayout layout = ExploreLayout.auto;
  
  /// === 더보기 기능을 위한 상태 관리 ===
  int _visibleRecipeCount = 2;           // 현재 표시되는 레시피 개수 (초기 2개)
  static const int _incrementCount = 2;   // 더보기 버튼 클릭 시 추가할 개수

  @override
  Widget build(BuildContext context) {
    final username = '요리사';

    return RefreshIndicator(
      onRefresh: () async {
        // 새로고침 시 초기 상태로 리셋
        setState(() {
          _visibleRecipeCount = 2;
        });
        await context.recipes.loadExplore();
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // === 1. 환영 메시지 ===
          // Selector로 레시피 개수만 감시
          Selector<RecipeController, int>(
            selector: (_, rc) => rc.explore.length,
            builder: (_, todayCount, __) {
              return CookTalkWelcome(
                userName: username,
                todayRecipeCount: todayCount,
              );
            },
          ),
          
          // === 2. 이번주 목표 (위로 이동) ===
          // Selector로 completedCount만 감시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Selector<RecipeController, int>(
              selector: (_, rc) => rc.completedCount,
              builder: (_, completedCount, __) {
                return HomeStats(
                  completedCount: completedCount,
                  weeklyGoal: 5,  // ✨ 주 7회 → 5회로 변경
                  cookedToday: false,
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          
          // === 3. 오늘의 추천 제목 (아래로 이동) ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '오늘의 추천',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // === 4. 추천 레시피 리스트 (초기 2개만 표시) ===
          // Consumer로 로딩 상태와 레시피 목록 감시
          Consumer<RecipeController>(
            builder: (context, rc, child) {
              // 로딩 중
              if (rc.loadingExplore) {
                return const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              // 레시피 없음
              if (rc.explore.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: EmptyState(
                    message: '추천 레시피가 없습니다',
                    subtitle: '새로운 레시피를 준비 중입니다',
                    icon: Icons.restaurant_menu,
                  ),
                );
              }
              
              // 현재 표시할 레시피 개수 계산
              // 전체 레시피보다 많이 표시하려고 하면 전체 개수로 제한
              final displayCount = _visibleRecipeCount > rc.explore.length
                  ? rc.explore.length
                  : _visibleRecipeCount;
              
              // 세로 리스트로 레시피 표시
              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),  // 부모 스크롤 사용
                shrinkWrap: true,                              // 높이 자동 조절
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayCount,  // ✨ 제한된 개수만 표시
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => RecipeListCard(recipe: rc.explore[i]),
              );
            },
          ),

          const SizedBox(height: 16),
          
          // === 5. 더보기 버튼 섹션 ===
          Consumer<RecipeController>(
            builder: (context, rc, child) {
              // 로딩 중이거나 레시피가 없으면 표시 안함
              if (rc.loadingExplore || rc.explore.isEmpty) {
                return const SizedBox.shrink();
              }
              
              // 더 표시할 레시피가 있는지 확인
              final hasMore = _visibleRecipeCount < rc.explore.length;
              
              // 남은 레시피 개수 계산
              final remainingCount = rc.explore.length - _visibleRecipeCount;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // 구분선
                    const Divider(),
                    
                    if (hasMore)
                      // ✨ 더보기 버튼 (남은 레시피가 있을 때)
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text(
                            '더 보기 (${remainingCount}개)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              // 2개씩 추가
                              _visibleRecipeCount += _incrementCount;
                            });
                            
                            // 부드러운 스크롤 효과 (선택사항)
                            // Future.delayed(const Duration(milliseconds: 100), () {
                            //   // 스크롤 로직
                            // });
                          },
                        ),
                      )
                    else
                      // ✨ 완료 메시지 (모든 레시피를 표시했을 때)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: context.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '모든 레시피를 확인했습니다 ✨',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // 접기 버튼 (선택사항 - 모두 펼쳤을 때만 표시)
                    if (!hasMore && _visibleRecipeCount > 2)
                      TextButton.icon(
                        icon: const Icon(Icons.keyboard_arrow_up),
                        label: const Text('접기'),
                        onPressed: () {
                          setState(() {
                            _visibleRecipeCount = 2;  // 초기 상태로 리셋
                          });
                          
                          // 페이지 상단으로 스크롤
                          // Scrollable.ensureVisible(context, ...);
                        },
                      ),
                  ],
                ),
              );
            },
          ),
            
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/recipe_controller.dart';
import '../core/utils/context_extensions.dart';
import '../data/mock/mock_data.dart';
import 'login_view.dart';
import 'link_account_view.dart';

/// 사용자 프로필, 통계, 설정을 보여주는 뷰입니다.
///
/// Provider와 Selector를 사용하여 상태 변경에 따라 UI를 효율적으로 업데이트합니다.
/// - 로그인 상태에 따라 프로필 정보 또는 로그인 프롬프트를 표시합니다.
/// - 사용자의 요리 통계를 보여주며, 일부 통계는 로그인한 사용자에게만 표시됩니다.
/// - 다크 모드, 알림 등 앱 설정을 변경할 수 있습니다.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // TODO: 이 설정 값들도 별도의 컨트롤러나 서비스로 관리하여 영구 저장해야 합니다.
  bool voiceGuide = true;
  bool pushNotify = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 프로필 또는 계정 연결 배너 표시
        Consumer<AuthController>(
          builder: (context, authController, _) {
            if (authController.isAnonymous) {
              // 익명 사용자: 계정 연결 배너만 표시 (프로필 대신)
              return _buildLinkAccountBanner(context);
            } else if (authController.isAuthenticated) {
              // 정식 사용자: 프로필 표시
              return _buildUserProfile(context);
            }
            // 비로그인 상태 (거의 발생 안 함, 자동 익명 로그인 때문)
            return _buildLoginPrompt(context);
          },
        ),

        const SizedBox(height: 16),
        
        _buildStatsSection(context),

        const SizedBox(height: 16),
        
        _buildSettingsSection(context),

        // [최적화] 로그인 상태가 변경될 때만 다시 빌드하여 계정 섹션을 표시하거나 숨깁니다.
        Selector<AuthController, bool>(
          selector: (_, auth) => auth.isAuthenticated,
          builder: (_, isLoggedIn, __) {
            if (!isLoggedIn) return const SizedBox.shrink(); // 숨김
            return _buildAccountSection(context);
          },
        ),
      ],
    );
  }

  /// 비로그인 사용자에게 로그인을 유도하는 위젯을 빌드합니다.
  Widget _buildLoginPrompt(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CookTalk에 오신 것을 환영합니다! 👋',
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '로그인하고 레시피를 저장하고 공유하세요',
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.push(const LoginView()),
            child: const Text('로그인 / 회원가입'),
          ),
        ],
      ),
    );
  }

  /// 로그인한 사용자의 프로필 정보(사진, 이름, 이메일)를 보여주는 위젯을 빌드합니다.
  Widget _buildUserProfile(BuildContext context) {
    // `Consumer`를 사용하여 AuthController의 변경사항을 감지하고 UI를 업데이트합니다.
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final user = authController.currentUser;
        
        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.secondaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: context.colorScheme.primary,
                backgroundImage: user?.photoURL.isNotEmpty == true
                    ? NetworkImage(user!.photoURL)
                    : null,
                child: user?.photoURL.isEmpty ?? true
                    ? Text(
                        user?.displayName.isNotEmpty == true
                            ? user!.displayName[0].toUpperCase()
                            : '😊',
                        style: TextStyle(
                          color: context.colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user?.displayName ?? "요리사"}님, 안녕하세요! 👋',
                      style: context.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'CookTalk과 함께하는 요리 여행',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// '완료한 요리', '좋아하는 레시피' 등 요리 관련 통계를 보여주는 섹션을 빌드합니다.
  Widget _buildStatsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('요리 통계', style: context.textTheme.titleMedium),
          const SizedBox(height: 12),
          
          // [MVP 하이브리드] 실제 데이터 + 목업 데이터 혼합
          // - 완료한 요리: 실제 (rc.completedCount)
          // - 스크랩한 레시피: 실제 (rc.savedRecipes.length)
          // - 좋아하는 레시피: 목업 (MockData.mockLikedRecipeCount)
          // - 팔로잉: 목업 (MockData.mockFollowingCount)
          Selector<RecipeController, _RecipeStats>(
            selector: (_, rc) {
              return _RecipeStats(
                // 실제 데이터: 완료한 요리 개수
                completed: rc.completedCount,
                // 목업 데이터: 좋아하는 레시피 개수
                liked: MockData.mockLikedRecipeCount,
                // 실제 데이터: 스크랩(북마크)한 레시피 개수
                scrapped: rc.savedRecipes.length,
                // 목업 데이터: 팔로잉 수
                following: MockData.mockFollowingCount,
              );
            },
            builder: (_, stats, __) {
              return Column(
                children: [
                  Row(
                    children: [
                      // 완료한 요리 (실제 데이터)
                      Expanded(
                        child: _StatTile(
                          color: context.colorScheme.errorContainer,
                          onColor: context.colorScheme.onErrorContainer,
                          value: stats.completed,
                          label: '완료한 요리',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 좋아하는 레시피 (목업 데이터)
                      Expanded(
                        child: _StatTile(
                          color: context.colorScheme.secondaryContainer,
                          onColor: context.colorScheme.onSecondaryContainer,
                          value: stats.liked,
                          label: '좋아하는 레시피',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // 스크랩한 레시피 (실제 데이터)
                      Expanded(
                        child: _StatTile(
                          color: context.colorScheme.tertiaryContainer,
                          onColor: context.colorScheme.onTertiaryContainer,
                          value: stats.scrapped,
                          label: '스크랩한 레시피',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 팔로잉 (목업 데이터)
                      Expanded(
                        child: _StatTile(
                          color: context.colorScheme.surface,
                          onColor: context.colorScheme.onSurface,
                          value: stats.following,
                          label: '팔로잉',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// '음성 가이드', '다크 모드' 등 앱 설정을 위한 섹션을 빌드합니다.
  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('설정', style: context.textTheme.titleMedium),
          const SizedBox(height: 12),
          _SettingRow(
            title: '음성 가이드',
            active: voiceGuide,
            onTap: () => setState(() => voiceGuide = !voiceGuide),
          ),
          const SizedBox(height: 8),
          _SettingRow(
            title: '푸시 알림',
            active: pushNotify,
            onTap: () => setState(() => pushNotify = !pushNotify),
          ),
          const SizedBox(height: 8),
          
          // [최적화] `AppController`의 `themeMode`가 변경될 때만 다크 모드 설정 UI를 다시 빌드합니다.
          Selector<AppController, ThemeMode>(
            selector: (_, app) => app.themeMode,
            builder: (context, themeMode, __) {
              final effectiveDark = themeMode == ThemeMode.dark || 
                  (themeMode == ThemeMode.system && context.isDarkMode);
              
              return _SettingRow(
                title: '다크 모드',
                active: effectiveDark,
                onTap: () => context.app.setThemeMode(
                  effectiveDark ? ThemeMode.light : ThemeMode.dark,
                ),
                activeLabel: '활성화',
                inactiveLabel: '비활성',
              );
            },
          ),
        ],
      ),
    );
  }

  /// 익명 사용자에게 계정 연결을 유도하는 배너를 빌드합니다.
  Widget _buildLinkAccountBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primaryContainer,
            context.colorScheme.tertiaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: context.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '로그인하고 더 많은 기능을 사용하세요',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '지금은 게스트로 사용 중입니다',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '로그인하면 더 많은 기능을 사용할 수 있어요:',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildBenefitRow(context, Icons.cloud_done, '모든 기기에서 데이터 동기화'),
          _buildBenefitRow(context, Icons.people, '레시피 공유 & 소셜 기능'),
          _buildBenefitRow(context, Icons.backup, '클라우드 자동 백업'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final result = await context.push(const LinkAccountView());
                if (result == true && context.mounted) {
                  context.showSuccessSnackBar('로그인 완료! 이제 모든 기능을 사용할 수 있습니다.');
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('로그인 / 회원가입'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: context.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: context.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// '로그아웃' 등 계정 관련 액션을 위한 섹션을 빌드합니다.
  Widget _buildAccountSection(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('계정', style: context.textTheme.titleMedium),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('로그아웃'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('로그아웃'),
                      content: const Text('정말 로그아웃하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => context.pop(false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => context.pop(true),
                          child: const Text('로그아웃'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true && context.mounted) {
                    await context.auth.signOut();
                    if (context.mounted) {
                      context.showSuccessSnackBar('로그아웃되었습니다');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `Selector` 위젯의 성능 최적화를 위해 사용되는 통계 데이터 래퍼 클래스입니다.
///
/// MVP에서는 실제 데이터와 목업 데이터를 혼합하여 사용합니다:
/// - completed: 실제 완료한 요리 개수
/// - scrapped: 실제 스크랩(북마크)한 레시피 개수
/// - liked: 목업 좋아하는 레시피 개수
/// - following: 목업 팔로잉 수
class _RecipeStats {
  final int completed;  // 실제
  final int liked;      // 목업
  final int scrapped;   // 실제
  final int following;  // 목업

  _RecipeStats({
    required this.completed,
    required this.liked,
    required this.scrapped,
    required this.following,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _RecipeStats &&
          runtimeType == other.runtimeType &&
          completed == other.completed &&
          liked == other.liked &&
          scrapped == other.scrapped &&
          following == other.following;

  @override
  int get hashCode =>
      completed.hashCode ^ liked.hashCode ^ scrapped.hashCode ^ following.hashCode;
}

/// 통계 정보를 표시하는 타일 위젯입니다.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.color,
    required this.onColor,
    required this.value,
    required this.label,
  });
  
  final Color color;
  final Color onColor;
  final int value;
  final String label;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: onColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: onColor)),
        ],
      ),
    );
  }
}

/// 설정 항목 하나를 표시하는 행 위젯입니다. (예: '다크 모드 [활성화]')
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.active,
    required this.onTap,
    this.activeLabel = '활성화',
    this.inactiveLabel = '비활성',
  });
  
  final String title;
  final bool active;
  final VoidCallback onTap;
  final String activeLabel;
  final String inactiveLabel;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: context.textTheme.titleMedium),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? context.colorScheme.secondaryContainer
                    : context.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                active ? activeLabel : inactiveLabel,
                style: TextStyle(
                  color: active
                      ? context.colorScheme.onSecondaryContainer
                      : context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

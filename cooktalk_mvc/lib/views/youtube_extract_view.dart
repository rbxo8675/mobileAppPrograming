import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/recipe_controller.dart';
import '../core/utils/snackbar_utils.dart';

class YoutubeExtractView extends StatefulWidget {
  const YoutubeExtractView({super.key});

  @override
  State<YoutubeExtractView> createState() => _YoutubeExtractViewState();
}

class _YoutubeExtractViewState extends State<YoutubeExtractView> with SingleTickerProviderStateMixin {
  final _urlCtrl = TextEditingController();
  bool _loading = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    if (_loading) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.smart_display_rounded,
                    size: 60,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(value),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),
              Text(
                'Gemini AI가 영상을 분석하고 있어요...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '잠시만 기다려주세요! 🎬',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('AI 레시피 추출')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoCard(
              icon: Icons.smart_display_rounded,
              title: 'AI 레시피 추출',
              message: 'Gemini AI가 유튜브 요리 영상을 분석하여 자동으로 레시피를 추출합니다. 재료, 조리 시간, 단계별 설명을 정확하게 파악해드려요.',
            ),
            const SizedBox(height: 16),
            _Section(
              title: '유튜브 영상 URL',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _urlCtrl,
                    decoration: InputDecoration(
                      hintText: 'https://www.youtube.com/watch?v=...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.link_rounded),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '요리 영상의 URL을 입력하세요. AI가 영상을 분석하여 레시피를 추출합니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading
                          ? null
                          : () async {
                              if (_urlCtrl.text.trim().isEmpty) {
                                SnackBarUtils.showWarning(
                                  context,
                                  'URL을 입력해 주세요',
                                );
                                return;
                              }
                              setState(() => _loading = true);
                              try {
                                await context.read<RecipeController>().importFromYouTube(_urlCtrl.text.trim());
                                if (!mounted) return;
                                SnackBarUtils.showSuccess(
                                  context,
                                  '레시피를 추가했습니다! 🎉',
                                  actionLabel: '보기',
                                  onAction: () => Navigator.pop(context),
                                );
                                Navigator.pop(context);
                              } catch (e) {
                                if (!mounted) return;
                                SnackBarUtils.showError(
                                  context,
                                  'AI 분석 중 오류가 발생했습니다',
                                  actionLabel: '다시 시도',
                                  onAction: () {},
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _loading = false);
                                }
                              }
                            },
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('레시피 추출하기'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: '사용 가이드',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _GuideItem(index: 1, title: '영상 URL 복사', body: '유튜브 요리 영상의 URL을 복사해주세요'),
                  SizedBox(height: 12),
                  _GuideItem(index: 2, title: 'AI 분석', body: 'Gemini AI가 영상을 분석하여 레시피를 추출합니다'),
                  SizedBox(height: 12),
                  _GuideItem(index: 3, title: '레시피 완성', body: '추출된 레시피로 바로 요리를 시작할 수 있습니다'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _WarnCard(
              title: 'AI 활용 주의사항',
              lines: const [
                '한국어 요리 영상에서 가장 정확한 결과를 얻을 수 있습니다',
                '영상이 너무 길거나 복잡한 경우 처리 시간이 늘어날 수 있습니다',
                '추출된 레시피는 참고용이며, 실제 조리 시 개인 취향에 맞게 조정해주세요',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.message});
  final IconData icon; final String title; final String message;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF0000).withOpacity(0.1),
            scheme.primaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF0000).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFF0000).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF0000),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title; final Widget child;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({required this.index, required this.title, required this.body});
  final int index; final String title; final String body;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$index',
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WarnCard extends StatelessWidget {
  const _WarnCard({required this.title, required this.lines});
  final String title; final List<String> lines;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l,
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


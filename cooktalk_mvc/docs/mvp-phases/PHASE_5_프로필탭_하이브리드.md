# Phase 5: 프로필 탭 하이브리드 데이터 구현

## 개요
프로필 탭에서 일부는 실제 데이터, 일부는 목업 데이터를 사용하는 하이브리드 방식을 구현합니다.

---

## 데이터 분류

| 항목 | 데이터 소스 | 설명 |
|-----|------------|------|
| 팔로잉 | 목업 | MockData.mockFollowingCount (12) |
| 스크랩한 레시피 | **실제** | 북마크된 레시피 개수 (savedRecipes.length) |
| 좋아하는 레시피 | 목업 | MockData.mockLikedRecipeCount (28) |
| 완료한 요리 | **실제** | RecipeController.completedCount |

---

## 현재 상태 분석

### 현재 파일: `lib/views/profile_view.dart`

```dart
Selector<RecipeController, _RecipeStats>(
  selector: (_, rc) {
    final Map<String, Recipe> all = {...};
    return _RecipeStats(
      completed: rc.completedCount,           // ✅ 실제 데이터
      liked: all.values.where((e) => e.liked).length,  // 현재 방식
      scrapped: all.values.where((e) => e.bookmarked).length,  // 현재 방식
    );
  },
  builder: (_, stats, __) {
    // 통계 타일 표시
  },
)
```

---

## 구현 작업

### 1. _RecipeStats 클래스 수정

```dart
class _RecipeStats {
  final int completed;    // 실제 데이터
  final int liked;        // 목업 데이터
  final int scrapped;     // 실제 데이터
  final int following;    // 목업 데이터

  _RecipeStats({
    required this.completed,
    required this.liked,
    required this.scrapped,
    required this.following,
  });

  // ... equals, hashCode 구현
}
```

### 2. ProfileView의 _buildStatsSection 수정

```dart
import '../data/mock/mock_data.dart';

Widget _buildStatsSection(BuildContext context) {
  return Container(
    // ... 스타일링
    child: Column(
      children: [
        Text('요리 통계', style: context.textTheme.titleMedium),
        const SizedBox(height: 12),

        Selector<RecipeController, _RecipeStats>(
          selector: (_, rc) {
            return _RecipeStats(
              // ✅ 실제 데이터: 완료한 요리 개수
              completed: rc.completedCount,

              // 🎭 목업 데이터: 좋아하는 레시피
              liked: MockData.mockLikedRecipeCount,

              // ✅ 실제 데이터: 스크랩(북마크)한 레시피 개수
              scrapped: rc.savedRecipes.length,

              // 🎭 목업 데이터: 팔로잉 수
              following: MockData.mockFollowingCount,
            );
          },
          builder: (_, stats, __) {
            return Column(
              children: [
                Row(
                  children: [
                    // 완료한 요리 (실제)
                    Expanded(
                      child: _StatTile(
                        color: context.colorScheme.errorContainer,
                        onColor: context.colorScheme.onErrorContainer,
                        value: stats.completed,
                        label: '완료한 요리',
                        isReal: true,  // 실제 데이터 표시
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 좋아하는 레시피 (목업)
                    Expanded(
                      child: _StatTile(
                        color: context.colorScheme.secondaryContainer,
                        onColor: context.colorScheme.onSecondaryContainer,
                        value: stats.liked,
                        label: '좋아하는 레시피',
                        isReal: false,  // 목업 데이터
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // 스크랩한 레시피 (실제)
                    Expanded(
                      child: _StatTile(
                        color: context.colorScheme.tertiaryContainer,
                        onColor: context.colorScheme.onTertiaryContainer,
                        value: stats.scrapped,
                        label: '스크랩한 레시피',
                        isReal: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 팔로잉 (목업)
                    Expanded(
                      child: _StatTile(
                        color: context.colorScheme.surface,
                        onColor: context.colorScheme.onSurface,
                        value: stats.following,
                        label: '팔로잉',
                        isReal: false,
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
```

### 3. _StatTile 위젯 수정 (선택사항)

```dart
class _StatTile extends StatelessWidget {
  final Color color;
  final Color onColor;
  final int value;
  final String label;
  final bool isReal;  // 실제 데이터 여부

  const _StatTile({
    required this.color,
    required this.onColor,
    required this.value,
    required this.label,
    this.isReal = true,
  });

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
          Row(
            children: [
              Text(label, style: TextStyle(color: onColor)),
              // 목업 데이터 표시 (개발 중에만)
              // if (!isReal) ...[
              //   const SizedBox(width: 4),
              //   Icon(Icons.science, size: 14, color: onColor.withOpacity(0.5)),
              // ],
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 통계 카드 UI

```
┌─────────────────────────────────────────────┐
│ 요리 통계                                    │
├─────────────────────┬─────────────────────┤
│                     │                     │
│    [실제] 3         │    [목업] 28        │
│    완료한 요리      │    좋아하는 레시피  │
│                     │                     │
├─────────────────────┼─────────────────────┤
│                     │                     │
│    [실제] 5         │    [목업] 12        │
│    스크랩한 레시피  │    팔로잉           │
│                     │                     │
└─────────────────────┴─────────────────────┘
```

---

## 체크리스트

- [ ] MockData import 추가
- [ ] _RecipeStats 클래스에 following 필드 추가
- [ ] 완료한 요리: rc.completedCount 유지 (실제)
- [ ] 좋아하는 레시피: MockData.mockLikedRecipeCount 사용
- [ ] 스크랩한 레시피: rc.savedRecipes.length 사용 (실제)
- [ ] 팔로잉: MockData.mockFollowingCount 사용
- [ ] equals/hashCode 업데이트

---

## 테스트 시나리오

1. 프로필 탭 접속
2. 통계 카드 4개 표시 확인
3. 레시피 북마크 추가/삭제 → 스크랩 개수 실시간 변경 확인
4. 요리 가이드 완료 → 완료한 요리 개수 증가 확인
5. 좋아하는 레시피 (28) 고정 표시 확인
6. 팔로잉 (12) 고정 표시 확인

---

## 로그인/설정 유지

로그인과 설정 섹션은 현재 구현 그대로 유지합니다:

- **로그인 섹션**: AuthController 사용 (실제)
- **설정 섹션**:
  - 음성 가이드: 로컬 상태
  - 푸시 알림: 로컬 상태
  - 다크 모드: AppController (실제)
- **계정 섹션**: 로그아웃 기능 (실제)

---

## 다음 단계
Phase 6에서 레시피 탭의 핵심 기능을 확인합니다.

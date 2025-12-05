# Phase 4: 피드 탭 목업 데이터 적용

## 개요
피드 탭(FeedView)에서 목업 데이터를 유지하고 정리합니다.
현재 FeedRepository는 이미 목업 데이터를 반환하고 있으므로 주로 데이터 정리 작업입니다.

---

## 현재 상태 분석

### 현재 파일: `lib/data/repositories/feed_repository.dart`
이미 하드코딩된 목업 데이터를 반환하고 있습니다.

```dart
Future<List<FeedPost>> getFeedPosts() async {
  await Future.delayed(const Duration(milliseconds: feedLoadDelay));
  return [
    const FeedPost(...), // Minji - Kimchi Fried Rice
    const FeedPost(...), // Jisoo - Creamy Bacon Pasta
  ];
}
```

---

## 구현 작업

### 1. FeedRepository 수정 - MockData 통합

```dart
import '../mock/mock_data.dart';
import '../../models/feed_post.dart';

class FeedRepository {
  Future<List<FeedPost>> getFeedPosts() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return MockData.feedPosts.map((data) => FeedPost(
      id: data['id'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      userImage: data['userImage'] as String?,
      recipeTitle: data['recipeTitle'] as String,
      recipeImage: data['recipeImage'] as String?,
      description: data['description'] as String,
      likes: data['likes'] as int,
      comments: data['comments'] as int,
      timeAgo: data['timeAgo'] as String,
      tags: (data['tags'] as List).cast<String>(),
      isFollowing: data['isFollowing'] as bool,
    )).toList();
  }

  Future<List<FeedPost>> getFollowingFeed() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 팔로잉한 사용자의 게시물만 필터링
    return MockData.feedPosts
        .where((data) => data['isFollowing'] == true)
        .map((data) => FeedPost(
          id: data['id'] as String,
          userId: data['userId'] as String,
          userName: data['userName'] as String,
          userImage: data['userImage'] as String?,
          recipeTitle: data['recipeTitle'] as String,
          recipeImage: data['recipeImage'] as String?,
          description: data['description'] as String,
          likes: data['likes'] as int,
          comments: data['comments'] as int,
          timeAgo: data['timeAgo'] as String,
          tags: (data['tags'] as List).cast<String>(),
          isFollowing: true,
        )).toList();
  }
}
```

---

## 표시되는 목업 데이터

### 전체 피드 (4개)

| 작성자 | 레시피 | 좋아요 | 댓글 | 시간 | 팔로잉 |
|-------|--------|--------|------|------|--------|
| 요리하는 민지 | 오늘의 김치찌개 | 156 | 23 | 2시간 전 | X |
| 파스타 러버 | 까르보나라 | 289 | 45 | 4시간 전 | O |
| 베이킹 초보 | 바나나 빵 | 98 | 12 | 6시간 전 | X |
| 건강식단 지수 | 그릭 샐러드 | 234 | 31 | 8시간 전 | O |

### 팔로잉 피드 (2개)
- 파스타 러버 - 까르보나라
- 건강식단 지수 - 그릭 샐러드

---

## FeedPostCard UI 구성

```
┌─────────────────────────────────────┐
│ 🧑 요리하는 민지     2시간 전    [팔로우] │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │                                 │ │
│ │        레시피 이미지            │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
│ 오늘의 김치찌개                       │
│ 오랜만에 만든 김치찌개! 돼지고기...   │
│                                     │
│ ❤️ 156   💬 23   🔖                 │
│ #오늘의요리 #한식 #집밥              │
└─────────────────────────────────────┘
```

---

## 체크리스트

- [ ] FeedRepository에서 MockData 사용하도록 변경
- [ ] getFollowingFeed() 메서드 수정
- [ ] 한글 데이터로 통일
- [ ] FeedView의 세그먼트 버튼(전체/팔로잉) 동작 확인

---

## 테스트 시나리오

1. 앱 실행 → 피드 탭 선택
2. "전체" 선택 시 4개 게시물 표시 확인
3. "팔로잉" 선택 시 2개 게시물만 표시 확인
4. 좋아요/스크랩 버튼 동작 확인 (UI만)
5. Pull-to-refresh 동작 확인

---

## 다음 단계
Phase 5에서 프로필 탭의 하이브리드 데이터를 구현합니다.

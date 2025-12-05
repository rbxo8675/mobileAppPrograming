import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/feed_repository.dart';
import '../../data/repositories/cooking_session_repository.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/voice_orchestrator.dart';
import '../../data/services/youtube_service.dart';

/// Repository 및 Service들을 Provider로 제공
/// 
/// 이를 통해:
/// 1. 싱글톤 패턴 관리가 용이
/// 2. 테스트 시 Mock 객체로 쉽게 교체 가능
/// 3. 의존성 주입이 명확해짐
class RepositoryProviders {
  static List<SingleChildWidget> get providers => [
    // ========== Repositories ==========
    Provider<AuthRepository>(
      create: (_) => AuthRepository(),
    ),
    
    Provider<RecipeRepository>(
      create: (_) => RecipeRepository(),
    ),
    
    Provider<FeedRepository>(
      create: (_) => FeedRepository(),
    ),
    
    Provider<CookingSessionRepository>(
      create: (_) => CookingSessionRepository(),
    ),
    
    // ========== Services ==========
    Provider<GeminiService>(
      create: (_) => GeminiService(),
      dispose: (_, service) => service.endChatSession(),
    ),
    
    ChangeNotifierProvider<VoiceOrchestrator>(
      create: (_) => VoiceOrchestrator(),
    ),
    
    Provider<YouTubeService>(
      create: (_) => YouTubeService(),
    ),
  ];
}

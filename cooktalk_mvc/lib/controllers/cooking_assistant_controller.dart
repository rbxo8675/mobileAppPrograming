import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/chat_message.dart';
import '../models/cooking_session.dart';
import '../models/timer.dart';
import '../data/services/gemini_service.dart';
import '../data/services/voice_orchestrator.dart';
import '../data/repositories/cooking_session_repository.dart';
import '../core/utils/logger.dart';

class CookingAssistantController extends ChangeNotifier {
  GeminiService _gemini;
  CookingSessionRepository _sessionRepo;
  VoiceOrchestrator _voiceOrchestrator;
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  Recipe? _currentRecipe;
  CookingSession? _activeSession;
  List<CookingSession> _completedSessions = [];
  bool _voiceMode = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  Recipe? get currentRecipe => _currentRecipe;
  CookingSession? get activeSession => _activeSession;
  List<CookingSession> get completedSessions => _completedSessions;
  bool get hasActiveSession => _activeSession != null;
  int get currentStep => _activeSession?.currentStep ?? 0;
  List<CookingTimer> get activeTimers => 
      _activeSession?.timers.where((t) => t.isActive || t.isPaused).toList() ?? [];
  bool get voiceMode => _voiceMode;
  bool get isListening => _voiceOrchestrator.isListening;
  VoiceOrchestrator get voiceOrchestrator => _voiceOrchestrator;

  CookingAssistantController(
    this._gemini,
    this._sessionRepo,
    this._voiceOrchestrator,
  );

  /// Services를 업데이트 (ProxyProvider용)
  void updateServices({
    GeminiService? gemini,
    CookingSessionRepository? sessionRepo,
    VoiceOrchestrator? voiceOrchestrator,
  }) {
    if (gemini != null) _gemini = gemini;
    if (sessionRepo != null) _sessionRepo = sessionRepo;
    if (voiceOrchestrator != null) _voiceOrchestrator = voiceOrchestrator;
  }

  Future<void> initialize() async {
    try {
      _activeSession = await _sessionRepo.getActiveSession();
      _completedSessions = await _sessionRepo.getCompletedSessions();
      await _voiceOrchestrator.initialize();
      Logger.info('Initialized cooking assistant controller');
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to initialize cooking assistant', e);
    }
  }
  
  void toggleVoiceMode() {
    _voiceMode = !_voiceMode;
    notifyListeners();
    Logger.info('Voice mode: $_voiceMode');
  }
  
  /// 음성 명령 처리 핸들러
  Future<void> _handleVoiceCommand(String recognizedText) async {
    try {
      final result = await _voiceOrchestrator.processCommand(recognizedText);
      Logger.info('Processed voice command: ${result.intent}');
      
      // 단계 변경이 있으면 세션 업데이트
      if (_activeSession != null) {
        _activeSession = _activeSession!.copyWith(
          currentStep: _voiceOrchestrator.currentStep,
        );
        await _sessionRepo.saveSession(_activeSession!);
      }
      
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to handle voice command', e);
    }
  }
  
  /// 수동으로 음성 인식 시작 (버튼 클릭)
  Future<void> startManualListening() async {
    if (_currentRecipe == null) return;
    
    await _voiceOrchestrator.startManualListening(_handleVoiceCommand);
    notifyListeners();
  }
  
  /// TTS 중단하고 즉시 음성 인식 (Push-to-Talk)
  Future<void> interruptAndListen() async {
    if (_currentRecipe == null) return;
    
    await _voiceOrchestrator.interruptAndListen(_handleVoiceCommand);
    notifyListeners();
  }
  
  Future<void> stopVoiceListening() async {
    await _voiceOrchestrator.stopListening();
    notifyListeners();
  }
  
  /// 자동 음성 인식 활성화/비활성화
  void setAutoListen(bool enabled) {
    _voiceOrchestrator.setAutoListenAfterTts(enabled);
    notifyListeners();
  }

  Future<void> startCooking(Recipe recipe, {String userId = 'current_user', bool withVoice = false}) async {
    try {
      if (_activeSession != null) {
        throw Exception('이미 진행 중인 요리가 있습니다');
      }

      final session = CookingSession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        recipeId: recipe.id,
        userId: userId,
        currentStep: 0,
        status: SessionStatus.inProgress,
        startedAt: DateTime.now(),
      );

      _activeSession = session;
      _currentRecipe = recipe;
      await _sessionRepo.saveSession(session);
      
      initializeChat(recipe);
      
      if (withVoice) {
        _voiceMode = true;
        // 음성 명령 콜백 설정 후 요리 세션 시작
        await _voiceOrchestrator.startCookingSession(
          recipe,
          onVoiceCommand: _handleVoiceCommand,
        );
      }
      
      Logger.info('Started cooking session for recipe: ${recipe.title}');
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to start cooking', e);
      rethrow;
    }
  }

  void initializeChat(Recipe recipe) {
    _currentRecipe = recipe;
    _messages.clear();
    
    _messages.add(ChatMessage.system(
      '안녕하세요! ${recipe.title} 레시피로 요리하시는군요. 궁금한 점이 있으면 언제든 물어보세요!',
    ));

    _gemini.startCookingChat(
      recipeTitle: recipe.title,
      ingredients: recipe.ingredients,
      steps: recipe.stepsAsStrings,
    );

    Logger.info('Cooking assistant initialized for recipe: ${recipe.title}');
    notifyListeners();
  }
  
  Future<void> nextStep() async {
    if (_activeSession == null) return;
    
    _activeSession = _activeSession!.copyWith(
      currentStep: _activeSession!.currentStep + 1,
    );
    
    await _sessionRepo.saveSession(_activeSession!);
    notifyListeners();
    Logger.info('Moved to step ${_activeSession!.currentStep}');
  }

  Future<void> previousStep() async {
    if (_activeSession == null || _activeSession!.currentStep == 0) return;
    
    _activeSession = _activeSession!.copyWith(
      currentStep: _activeSession!.currentStep - 1,
    );
    
    await _sessionRepo.saveSession(_activeSession!);
    notifyListeners();
    Logger.info('Moved back to step ${_activeSession!.currentStep}');
  }

  Future<void> pauseSession() async {
    if (_activeSession == null) return;
    
    _activeSession = _activeSession!.copyWith(
      status: SessionStatus.paused,
      pausedAt: DateTime.now(),
    );
    
    await _sessionRepo.saveSession(_activeSession!);
    notifyListeners();
    Logger.info('Paused cooking session');
  }

  Future<void> resumeSession() async {
    if (_activeSession == null) return;
    
    _activeSession = _activeSession!.copyWith(
      status: SessionStatus.inProgress,
      pausedAt: null,
    );
    
    await _sessionRepo.saveSession(_activeSession!);
    notifyListeners();
    Logger.info('Resumed cooking session');
  }

  Future<void> completeCooking({String? photoPath, int? rating, String? notes}) async {
    if (_activeSession == null) return;
    
    _activeSession = _activeSession!.copyWith(
      status: SessionStatus.completed,
      completedAt: DateTime.now(),
      photoPath: photoPath,
      rating: rating,
      notes: notes,
    );
    
    await _sessionRepo.saveSession(_activeSession!);
    _completedSessions.insert(0, _activeSession!);
    _activeSession = null;
    
    notifyListeners();
    Logger.info('Completed cooking session');
  }

  Future<void> cancelCooking() async {
    if (_activeSession == null) return;
    
    _activeSession = _activeSession!.copyWith(
      status: SessionStatus.cancelled,
    );
    
    await _sessionRepo.saveSession(_activeSession!);
    _activeSession = null;
    
    notifyListeners();
    Logger.info('Cancelled cooking session');
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage.user(content);
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    try {
      Logger.debug('Sending message to Gemini: $content');
      final response = await _gemini.sendChatMessage(content);
      
      final assistantMessage = ChatMessage.assistant(response);
      _messages.add(assistantMessage);
      
      Logger.info('Received response from Gemini');
    } catch (e) {
      Logger.error('Failed to send message', e);
      
      final errorMessage = ChatMessage.assistant(
        '죄송합니다. 메시지를 처리하는 중 오류가 발생했습니다. 다시 시도해주세요.',
        isError: true,
      );
      _messages.add(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> askIngredientSubstitution(String ingredient) async {
    _isLoading = true;
    notifyListeners();

    try {
      Logger.debug('Asking for ingredient substitution: $ingredient');
      final response = await _gemini.getIngredientSubstitution(ingredient);
      
      final message = ChatMessage.assistant(response);
      _messages.add(message);
    } catch (e) {
      Logger.error('Failed to get ingredient substitution', e);
      
      final errorMessage = ChatMessage.assistant(
        '재료 대체 정보를 가져오는데 실패했습니다.',
        isError: true,
      );
      _messages.add(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addQuickQuestion(String question) {
    sendMessage(question);
  }

  void clearChat() {
    _messages.clear();
    _gemini.endChatSession();
    _currentRecipe = null;
    Logger.info('Cooking assistant chat cleared');
    notifyListeners();
  }

  @override
  void dispose() {
    _gemini.endChatSession();
    super.dispose();
  }
}

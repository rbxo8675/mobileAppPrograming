import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../../models/voice_command.dart';

/// Gemini AI 모델과의 모든 상호작용을 관리하는 서비스 클래스입니다.
///
/// 레시피 생성, 요리 관련 질문 답변, 음성 명령 분석 등 다양한 AI 기능을 제공합니다.
class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _initialized = false;

  GeminiService();

  /// Gemini 모델이 초기화되었는지 확인하고, 안 되어 있다면 초기화를 진행합니다.
  ///
  /// API 키를 로드하고 [GenerativeModel] 인스턴스를 생성합니다.
  void _ensureInitialized() {
    if (_initialized) return;
    
    try {
      final apiKey = AppConfig.geminiApiKey;
      if (apiKey.isEmpty) {
        throw GeminiException('Gemini API key not configured');
      }
      
      // API 설정과 함께 Gemini 모델 초기화
      _model = GenerativeModel(
        model: ApiConstants.geminiModel,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: ApiConstants.temperature,
          maxOutputTokens: ApiConstants.maxTokens,
        ),
      );
      _initialized = true;
      Logger.info('Gemini model initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize Gemini model', e);
      throw GeminiException('Failed to initialize Gemini', originalError: e);
    }
  }

  /// 사용자의 음성 명령(텍스트)를 분석하여 정형화된 [VoiceCommand] 객체로 변환합니다.
  ///
  /// Gemini에게 음성 명령의 의도를 파악하도록 요청하고, 그 결과를 JSON으로 받아 파싱합니다.
  /// 실패 시 [VoiceCommand.unknown]을 반환합니다.
  Future<VoiceCommand> parseVoiceCommand(String text) async {
    try {
      _ensureInitialized();
      final prompt = _buildVoiceCommandPrompt(text);
      
      // Gemini API를 호출하여 콘텐츠 생성
      final response = await _model!.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        Logger.warning('Received empty response from Gemini for voice command');
        return VoiceCommand.unknown;
      }
      
      // Gemini의 응답(JSON)을 파싱하여 VoiceCommand 객체로 변환
      return _parseCommandFromGeminiResponse(responseText);

    } catch (e) {
      Logger.error('Failed to parse voice command with Gemini', e);
      return VoiceCommand.unknown;
    }
  }

  /// Gemini가 반환한 JSON 형식의 문자열을 [VoiceCommand] 객체로 파싱합니다.
  VoiceCommand _parseCommandFromGeminiResponse(String responseText) {
    try {
      // 응답에서 JSON 부분만 깔끔하게 추출
      final jsonString = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonResponse = jsonDecode(jsonString) as Map<String, dynamic>;

      final commandStr = jsonResponse['command'] as String?;
      if (commandStr == null) return VoiceCommand.unknown;
      
      // 문자열을 VoiceCommandType enum 값으로 변환
      final commandType = VoiceCommandType.values.firstWhere(
        (e) => e.name == commandStr,
        orElse: () => VoiceCommandType.unknown,
      );

      // 파싱된 명령어 타입에 따라 적절한 VoiceCommand 객체 생성
      switch (commandType) {
        case VoiceCommandType.next:
          return VoiceCommand.next;
        case VoiceCommandType.previous:
          return VoiceCommand.previous;
        case VoiceCommandType.startTimer:
          return VoiceCommand.startTimer;
        case VoiceCommandType.timerWithMinutes:
          final minutes = jsonResponse['data'] as int?;
          return minutes != null ? VoiceCommand.timer(minutes) : VoiceCommand.unknown;
        case VoiceCommandType.stop:
          return VoiceCommand.stop;
        case VoiceCommandType.repeat:
          return VoiceCommand.repeat;
        case VoiceCommandType.restart:
          return VoiceCommand.restart;
        case VoiceCommandType.question:
           final question = jsonResponse['data'] as String?;
           return question != null ? VoiceCommand.question(question) : VoiceCommand.unknown;
        default:
          return VoiceCommand.unknown;
      }
    } catch (e) {
      Logger.error('Failed to parse JSON from Gemini response: $responseText', e);
      return VoiceCommand.unknown;
    }
  }

  /// Gemini에게 음성 명령 분석을 요청하기 위한 프롬프트를 생성합니다.
  String _buildVoiceCommandPrompt(String userText) {
    // Gemini에게 역할을 부여하고, 수행할 작업과 출력 형식을 명확히 지시합니다.
    return '''
You are a voice command parser for a cooking app.
Analyze the user's spoken text and classify it into one of the following commands.
Respond with ONLY a JSON object in the format `{"command": "command_name", "data": "value"}`.

Available commands:
- `next`: Go to the next step. (e.g., "다음", "다음 단계")
- `previous`: Go to the previous step. (e.g., "이전", "뒤로 가줘")
- `startTimer`: Starts the default timer for the current step. (e.g., "타이머 시작")
- `timerWithMinutes`: Set a timer for a specific duration. `data` should be the number of minutes (integer). (e.g., "10분 타이머", "5분 맞춰줘")
- `stop`: Stop the timer or any other current action. (e.g., "정지", "멈춰")
- `repeat`: Repeat the current step's instruction. (e.g., "다시 말해줘", "한 번 더")
- `restart`: Go back to the first step of the recipe. (e.g., "처음부터", "다시 시작")
- `question`: The user is asking a general question. `data` should be the user's question (string). (e.g., "소금은 얼마나?", "이거 맞아?")

User's spoken text: "$userText"

JSON response:
''';
  }

  /// YouTube 비디오 정보(제목, 설명, 자막)로부터 레시피를 추출합니다.
  Future<String> generateRecipeFromVideo({
    required String videoTitle,
    required String videoDescription,
    String? transcript,
  }) async {
    try {
      _ensureInitialized();
      final prompt = _buildRecipeExtractionPrompt(
        videoTitle,
        videoDescription,
        transcript,
      );

      Logger.debug('Generating recipe from video: $videoTitle');
      final response = await _model!.generateContent([Content.text(prompt)]);

      if (response.text == null || response.text!.isEmpty) {
        throw GeminiException('Empty response from Gemini');
      }

      Logger.info('Recipe generated successfully from video');
      return response.text!;
    } catch (e) {
      Logger.error('Failed to generate recipe from video', e);
      throw GeminiException('Failed to generate recipe', originalError: e);
    }
  }

  /// 현재 레시피 정보와 사용자의 질문을 바탕으로 요리 관련 답변을 생성합니다.
  Future<String> getCookingAssistance({
    required String recipeTitle,
    required List<String> ingredients,
    required List<String> steps,
    required String userQuestion,
  }) async {
    try {
      _ensureInitialized();
      final prompt = _buildCookingAssistancePrompt(
        recipeTitle,
        ingredients,
        steps,
        userQuestion,
      );

      Logger.debug('Getting cooking assistance for: $recipeTitle');
      final response = await _model!.generateContent([Content.text(prompt)]);

      if (response.text == null || response.text!.isEmpty) {
        throw GeminiException('Empty response from Gemini');
      }

      return response.text!;
    } catch (e) {
      Logger.error('Failed to get cooking assistance', e);
      throw GeminiException('Failed to get cooking assistance', originalError: e);
    }
  }

  /// 특정 레시피에 대한 대화형 채팅 세션을 시작합니다.
  ChatSession startCookingChat({
    required String recipeTitle,
    required List<String> ingredients,
    required List<String> steps,
  }) {
    _ensureInitialized();
    // Gemini에게 시스템 메시지를 전달하여 역할을 부여합니다.
    final systemPrompt = '''
당신은 친절한 요리 도우미입니다. 
레시피: $recipeTitle

재료:
${ingredients.map((i) => '- $i').join('\n')}

조리 단계:
${steps.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

사용자가 요리 중 질문하면 간단명료하게 답변해주세요.
재료 대체, 조리 팁, 시간 조절 등에 대해 도움을 주세요.
답변은 한국어로 친근하게 해주세요.
''';

    _chatSession = _model!.startChat(
      history: [
        Content.text(systemPrompt),
        Content.model([TextPart('네, 요리를 도와드리겠습니다! 궁금한 점을 물어보세요.')]),
      ],
    );

    Logger.info('Cooking chat session started for: $recipeTitle');
    return _chatSession!;
  }

  /// 현재 진행 중인 채팅 세션에 메시지를 전송하고 답변을 받습니다.
  Future<String> sendChatMessage(String message) async {
    if (_chatSession == null) {
      throw GeminiException('Chat session not initialized');
    }

    try {
      Logger.debug('Sending chat message: $message');
      final response = await _chatSession!.sendMessage(Content.text(message));

      if (response.text == null || response.text!.isEmpty) {
        throw GeminiException('Empty response from chat');
      }

      return response.text!;
    } catch (e) {
      Logger.error('Failed to send chat message', e);
      throw GeminiException('Failed to send message', originalError: e);
    }
  }

  /// 현재 채팅 세션을 종료합니다.
  void endChatSession() {
    _chatSession = null;
    Logger.info('Cooking chat session ended');
  }

  /// YouTube 레시피 추출을 위한 프롬프트를 생성합니다.
  String _buildRecipeExtractionPrompt(
    String title,
    String description,
    String? transcript,
  ) {
    return '''
다음 YouTube 영상에서 레시피를 추출해주세요.

제목: $title
설명: $description
${transcript != null ? '자막: $transcript' : ''}

다음 JSON 형식으로 응답해주세요:
{
  "title": "레시피 제목",
  "durationMinutes": 30,
  "servings": 2,
  "difficulty": "쉬움",
  "ingredients": ["재료1", "재료2"],
  "steps": ["단계1", "단계2"],
  "description": "레시피 설명",
  "tags": ["태그1", "태그2"]
}

재료와 조리 단계는 명확하고 구체적으로 작성해주세요.
난이도는 "쉬움", "보통", "어려움" 중 선택해주세요.
''';
  }

  /// 요리 중 질문에 대한 답변 생성을 위한 프롬프트를 생성합니다.
  String _buildCookingAssistancePrompt(
    String recipeTitle,
    List<String> ingredients,
    List<String> steps,
    String userQuestion,
  ) {
    return '''
레시피: $recipeTitle

재료:
${ingredients.map((i) => '- $i').join('\n')}

조리 단계:
${steps.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

사용자 질문: $userQuestion

위 레시피를 참고하여 사용자의 질문에 간단명료하게 답변해주세요.
답변은 한국어로 친근하게 해주세요.
''';
  }

  /// 특정 재료에 대한 대체재를 추천받습니다.
  Future<String> getIngredientSubstitution(String ingredient) async {
    try {
      _ensureInitialized();
      final prompt = '''
요리 재료 "$ingredient"의 대체재를 3가지 추천해주세요.
각 대체재마다 간단한 설명을 붙여주세요.
형식:
1. 대체재1 - 설명
2. 대체재2 - 설명
3. 대체재3 - 설명
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? '대체재를 찾을 수 없습니다.';
    } catch (e) {
      Logger.error('Failed to get ingredient substitution', e);
      throw GeminiException('Failed to get substitution', originalError: e);
    }
  }

  /// 사용 가능한 재료 목록으로 만들 수 있는 레시피를 추천받습니다.
  Future<List<String>> generateRecipeSuggestions(List<String> availableIngredients) async {
    try {
      _ensureInitialized();
      final prompt = '''
다음 재료들로 만들 수 있는 레시피 5가지를 추천해주세요:
${availableIngredients.map((i) => '- $i').join('\n')}

레시피 이름만 간단하게 나열해주세요.
형식:
1. 레시피명
2. 레시피명
...
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      if (response.text == null) return [];

      // 응답 텍스트를 파싱하여 레시피 이름 리스트로 변환
      return response.text!
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
          .toList();
    } catch (e) {
      Logger.error('Failed to generate recipe suggestions', e);
      return [];
    }
  }
}

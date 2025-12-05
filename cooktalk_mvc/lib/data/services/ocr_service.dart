import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';

class OcrService {
  late final TextRecognizer _textRecognizer;
  late final GenerativeModel _geminiModel;

  OcrService() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    _geminiModel = GenerativeModel(
      model: ApiConstants.geminiModel,
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: ApiConstants.temperature,
        maxOutputTokens: ApiConstants.maxTokens,
      ),
    );
    Logger.info('OCR service initialized');
  }

  Future<String> extractTextFromImage(File imageFile) async {
    try {
      Logger.debug('Starting OCR on image: ${imageFile.path}');
      
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final extractedText = recognizedText.text;
      
      if (extractedText.isEmpty) {
        throw OcrException('No text found in image');
      }
      
      Logger.info('OCR extracted ${extractedText.length} characters');
      return extractedText;
    } catch (e) {
      Logger.error('OCR text extraction failed', e);
      throw OcrException('Failed to extract text', originalError: e);
    }
  }

  Future<Map<String, dynamic>> parseRecipeFromText(String ocrText) async {
    try {
      Logger.debug('Parsing recipe from OCR text');
      
      final prompt = _buildRecipeParsingPrompt(ocrText);
      final response = await _geminiModel.generateContent([Content.text(prompt)]);
      
      if (response.text == null || response.text!.isEmpty) {
        throw GeminiException('Empty response from Gemini');
      }
      
      final jsonText = _extractJsonFromResponse(response.text!);
      Logger.info('Recipe parsed successfully from OCR text');
      
      return _parseJsonResponse(jsonText);
    } catch (e) {
      Logger.error('Failed to parse recipe from OCR text', e);
      throw GeminiException('Failed to parse recipe', originalError: e);
    }
  }

  Future<Map<String, dynamic>> scanRecipeFromImage(File imageFile) async {
    try {
      final extractedText = await extractTextFromImage(imageFile);
      final parsedRecipe = await parseRecipeFromText(extractedText);
      
      Logger.info('Recipe scanned successfully from image');
      return parsedRecipe;
    } catch (e) {
      Logger.error('Failed to scan recipe from image', e);
      rethrow;
    }
  }

  String _buildRecipeParsingPrompt(String ocrText) {
    return '''
다음은 레시피북이나 요리책에서 OCR로 추출한 텍스트입니다.
이 텍스트를 분석하여 레시피 정보를 추출해주세요.

OCR 텍스트:
$ocrText

다음 JSON 형식으로 응답해주세요:
{
  "title": "레시피 제목",
  "durationMinutes": 30,
  "servings": 2,
  "difficulty": "쉬움",
  "ingredients": ["재료1 100g", "재료2 2개"],
  "steps": [
    {"instruction": "단계1 설명", "timerMinutes": 5, "autoStart": false},
    {"instruction": "단계2 설명", "timerMinutes": null, "autoStart": false}
  ],
  "description": "레시피 간단 설명",
  "tags": ["한식", "국물요리"]
}

중요:
- 재료는 분량과 함께 명확하게 작성
- 조리 단계는 순서대로 나열
- 시간이 명시된 단계는 timerMinutes에 분 단위로 입력
- 난이도는 "쉬움", "보통", "어려움" 중 선택
- 태그는 요리 종류, 재료, 조리법 등으로 분류
- JSON만 응답하고 다른 텍스트는 포함하지 마세요
''';
  }

  String _extractJsonFromResponse(String responseText) {
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
    if (jsonMatch == null) {
      throw GeminiException('No JSON found in response');
    }
    return jsonMatch.group(0)!;
  }

  Map<String, dynamic> _parseJsonResponse(String jsonText) {
    try {
      return {
        'title': _extractValue(jsonText, 'title'),
        'durationMinutes': _extractNumber(jsonText, 'durationMinutes'),
        'servings': _extractNumber(jsonText, 'servings'),
        'difficulty': _extractValue(jsonText, 'difficulty'),
        'ingredients': _extractArray(jsonText, 'ingredients'),
        'steps': _extractStepsArray(jsonText, 'steps'),
        'description': _extractValue(jsonText, 'description'),
        'tags': _extractArray(jsonText, 'tags'),
      };
    } catch (e) {
      Logger.error('Failed to parse JSON response', e);
      throw GeminiException('Invalid JSON format', originalError: e);
    }
  }

  String _extractValue(String jsonText, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*"([^"]*)"');
    final match = pattern.firstMatch(jsonText);
    return match?.group(1) ?? '';
  }

  int _extractNumber(String jsonText, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*(\\d+)');
    final match = pattern.firstMatch(jsonText);
    return int.tryParse(match?.group(1) ?? '0') ?? 0;
  }

  List<String> _extractArray(String jsonText, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*\\[([^\\]]*)\\]');
    final match = pattern.firstMatch(jsonText);
    if (match == null) return [];
    
    final arrayContent = match.group(1) ?? '';
    return arrayContent
        .split(',')
        .map((item) => item.trim().replaceAll('"', ''))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _extractStepsArray(String jsonText, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*\\[([^\\]]*(?:\\{[^}]*\\}[^\\]]*)*)\\]', multiLine: true);
    final match = pattern.firstMatch(jsonText);
    if (match == null) return [];
    
    final stepsContent = match.group(1) ?? '';
    final stepPattern = RegExp(r'\{[^}]*\}');
    final stepMatches = stepPattern.allMatches(stepsContent);
    
    return stepMatches.map((stepMatch) {
      final stepJson = stepMatch.group(0)!;
      return {
        'instruction': _extractValue(stepJson, 'instruction'),
        'timerMinutes': _extractTimerMinutes(stepJson),
        'autoStart': _extractBoolean(stepJson, 'autoStart'),
      };
    }).toList();
  }

  int? _extractTimerMinutes(String stepJson) {
    final pattern = RegExp('"timerMinutes"\\s*:\\s*(\\d+|null)');
    final match = pattern.firstMatch(stepJson);
    final value = match?.group(1);
    if (value == null || value == 'null') return null;
    return int.tryParse(value);
  }

  bool _extractBoolean(String jsonText, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*(true|false)');
    final match = pattern.firstMatch(jsonText);
    return match?.group(1) == 'true';
  }

  void dispose() {
    _textRecognizer.close();
    Logger.info('OCR service disposed');
  }
}

class OcrException extends AppException {
  OcrException(super.message, {super.originalError});
}

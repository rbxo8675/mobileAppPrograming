import 'dart:convert';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import 'gemini_service.dart';

class YouTubeService {
  final _yt = YoutubeExplode();
  final _gemini = GeminiService();

  Future<Map<String, dynamic>> extractRecipeFromUrl(String url) async {
    try {
      Logger.info('Extracting recipe from YouTube URL: $url');

      final videoId = VideoId(url);
      final video = await _yt.videos.get(videoId);
      
      Logger.debug('Video title: ${video.title}');

      String? transcript;
      
      try {
        final manifest = await _yt.videos.closedCaptions.getManifest(videoId);
        if (manifest.tracks.isNotEmpty) {
          final trackInfo = manifest.tracks.first;
          final track = await _yt.videos.closedCaptions.get(trackInfo);
          final captionsList = track.captions;
          if (captionsList != null && captionsList.isNotEmpty) {
            transcript = captionsList.map((c) => c.text).join(' ');
            Logger.debug('Transcript extracted (${transcript?.length ?? 0} chars)');
          }
        }
      } catch (e) {
        Logger.warning('Failed to extract transcript: $e');
      }

      final geminiResponse = await _gemini.generateRecipeFromVideo(
        videoTitle: video.title,
        videoDescription: video.description,
        transcript: transcript,
      );

      final recipeData = _parseGeminiRecipeResponse(geminiResponse);

      recipeData['imagePath'] = video.thumbnails.highResUrl;

      Logger.info('Recipe extracted successfully from YouTube');
      return recipeData;
    } catch (e) {
      Logger.error('Failed to extract recipe from YouTube', e);
      
      if (e is GeminiException) {
        rethrow;
      }
      
      throw YouTubeException(
        'YouTube에서 레시피를 추출할 수 없습니다',
        originalError: e,
      );
    } finally {
      _yt.close();
    }
  }

  Map<String, dynamic> _parseGeminiRecipeResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw const FormatException('No JSON found in response');
      }

      final jsonString = jsonMatch.group(0)!;
      final data = json.decode(jsonString) as Map<String, dynamic>;

      return {
        'title': data['title'] ?? 'Unknown Recipe',
        'durationMinutes': data['durationMinutes'] ?? 30,
        'servings': data['servings'] ?? 2,
        'difficulty': data['difficulty'] ?? '보통',
        'ingredients': (data['ingredients'] as List?)?.cast<String>() ?? [],
        'steps': (data['steps'] as List?)?.cast<String>() ?? [],
        'description': data['description'] ?? '',
        'tags': (data['tags'] as List?)?.cast<String>() ?? [],
      };
    } catch (e) {
      Logger.error('Failed to parse Gemini response', e);
      
      return {
        'title': 'Parsed Recipe',
        'durationMinutes': 30,
        'ingredients': ['재료를 확인해주세요'],
        'steps': ['조리 단계를 확인해주세요'],
      };
    }
  }

  Future<bool> validateYouTubeUrl(String url) async {
    try {
      VideoId.parseVideoId(url);
      return true;
    } catch (e) {
      return false;
    }
  }
}

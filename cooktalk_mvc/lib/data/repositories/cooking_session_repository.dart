import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/cooking_session.dart';
import '../../core/utils/logger.dart';

class CookingSessionRepository {
  static const String _sessionKey = 'cooking_sessions';
  static const String _activeSessionKey = 'active_session';

  Future<List<CookingSession>> getAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_sessionKey);
      
      if (sessionsJson == null) return [];
      
      final List<dynamic> sessionsList = json.decode(sessionsJson);
      return sessionsList
          .map((s) => CookingSession.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Logger.error('Failed to load cooking sessions', e);
      return [];
    }
  }

  Future<List<CookingSession>> getCompletedSessions() async {
    try {
      final sessions = await getAllSessions();
      return sessions.where((s) => s.isCompleted).toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    } catch (e) {
      Logger.error('Failed to load completed sessions', e);
      return [];
    }
  }

  Future<CookingSession?> getActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_activeSessionKey);
      
      if (sessionJson == null) return null;
      
      return CookingSession.fromJson(json.decode(sessionJson));
    } catch (e) {
      Logger.error('Failed to load active session', e);
      return null;
    }
  }

  Future<void> saveSession(CookingSession session) async {
    try {
      final sessions = await getAllSessions();
      final index = sessions.indexWhere((s) => s.id == session.id);
      
      if (index != -1) {
        sessions[index] = session;
      } else {
        sessions.add(session);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sessionKey,
        json.encode(sessions.map((s) => s.toJson()).toList()),
      );
      
      if (session.isActive || session.isPaused) {
        await prefs.setString(_activeSessionKey, json.encode(session.toJson()));
      } else {
        await prefs.remove(_activeSessionKey);
      }
      
      Logger.info('Saved cooking session: ${session.id}');
    } catch (e) {
      Logger.error('Failed to save cooking session', e);
      rethrow;
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      final sessions = await getAllSessions();
      sessions.removeWhere((s) => s.id == sessionId);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sessionKey,
        json.encode(sessions.map((s) => s.toJson()).toList()),
      );
      
      final activeSession = await getActiveSession();
      if (activeSession?.id == sessionId) {
        await prefs.remove(_activeSessionKey);
      }
      
      Logger.info('Deleted cooking session: $sessionId');
    } catch (e) {
      Logger.error('Failed to delete cooking session', e);
      rethrow;
    }
  }

  Future<void> clearActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeSessionKey);
      Logger.info('Cleared active session');
    } catch (e) {
      Logger.error('Failed to clear active session', e);
    }
  }
}

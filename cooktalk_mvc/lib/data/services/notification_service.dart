import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    _isInitialized = true;
    Logger.info('Notification service initialized');
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    Logger.debug('Notification tapped: ${response.payload}');
  }
  
  Future<void> showTimerCompleteNotification({
    required String recipeTitle,
    required int stepNumber,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'cooking_timer',
      '요리 타이머',
      channelDescription: '요리 단계별 타이머 알림',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      0,
      '⏰ 타이머 완료!',
      '$recipeTitle - $stepNumber단계가 완료되었습니다',
      details,
      payload: 'timer_complete',
    );
  }
  
  Future<void> showTimerStartNotification({
    required String recipeTitle,
    required int minutes,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'cooking_timer',
      '요리 타이머',
      channelDescription: '요리 단계별 타이머 알림',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
    );
    
    const details = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      1,
      '⏱️ 타이머 진행 중',
      '$recipeTitle - $minutes분 타이머',
      details,
      payload: 'timer_running',
    );
  }
  
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
  
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}

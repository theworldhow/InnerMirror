import 'package:shared_preferences/shared_preferences.dart';
import 'life_log_service.dart';

class PushNotificationService {
  static PushNotificationService? _instance;
  static PushNotificationService get instance => _instance ??= PushNotificationService._();
  
  PushNotificationService._();
  
  final LifeLogService _lifeLog = LifeLogService.instance;

  Future<void> sendDailyNotification() async {
    try {
      // Generate "One Thing" notification (max 12 words)
      final notification = await _generateOneThing();
      
      if (notification.isNotEmpty) {
        // In production, use flutter_local_notifications or firebase_messaging
        // For now, we'll store it and it can be shown when app opens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('daily_notification', notification);
        await prefs.setInt('daily_notification_time', DateTime.now().millisecondsSinceEpoch);
        
        // TODO: Actually send push notification
        // await FlutterLocalNotifications().show(0, 'InnerMirror', notification);
      }
    } catch (e) {
      print('Notification error: $e');
    }
  }

  Future<String> _generateOneThing() async {
    // Using simple NLP instead of LLM
    final recentEntries = await _lifeLog.getRecentEntries(count: 10);
    if (recentEntries.isEmpty) {
      return 'Start journaling today.';
    }
    
    // Generate simple notification based on recent patterns
    final activities = <String, int>{};
    for (final entry in recentEntries) {
      final type = entry['type'] as String? ?? 'unknown';
      activities[type] = (activities[type] ?? 0) + 1;
    }
    
    if (activities.isEmpty) {
      return 'Reflect on your day.';
    }
    
    // Suggest most common activity
    final topActivity = activities.entries.reduce((a, b) => a.value > b.value ? a : b);
    return 'Continue focusing on ${topActivity.key}.';
  }

  Future<String?> getDailyNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('daily_notification');
  }
}


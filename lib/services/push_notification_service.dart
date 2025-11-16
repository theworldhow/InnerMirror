import 'package:shared_preferences/shared_preferences.dart';
import 'life_log_service.dart';
import 'soul_model_service.dart';

class PushNotificationService {
  static PushNotificationService? _instance;
  static PushNotificationService get instance => _instance ??= PushNotificationService._();
  
  PushNotificationService._();
  
  final LifeLogService _lifeLog = LifeLogService.instance;
  final SoulModelService _soulModel = SoulModelService.instance;

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
    if (_soulModel.state != ModelState.ready) {
      return '';
    }

    final lifeLogContent = await _lifeLog.getLifeLogContent();
    
    final prompt = """Generate a maximum 12-word notification that tells me one thing I need to do today based on my life_log.jsonl.

Be specific and use real data. Examples:
- "Call Mom. You haven't said I love you in 41 days."
- "Write. You create best at coffee shops."
- "Sleep. Your HRV dropped 30% this week."

Output ONLY the notification text, nothing else.

Here is my life_log.jsonl:
$lifeLogContent""";

    try {
      final response = await _soulModel.generateResponse(prompt);
      // Trim to 12 words max
      final words = response.trim().split(RegExp(r'\s+'));
      return words.take(12).join(' ');
    } catch (e) {
      return '';
    }
  }

  Future<String?> getDailyNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('daily_notification');
  }
}


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/life_log_service.dart';
import '../services/embedding_service.dart';

final lifeLogServiceProvider = Provider<LifeLogService>((ref) {
  return LifeLogService.instance;
});

final totalMomentsProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(lifeLogServiceProvider);
  return await service.getTotalMoments();
});

final lastIngestionTimeProvider = FutureProvider<DateTime?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final timestamp = prefs.getInt('last_ingestion_time');
  if (timestamp == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(timestamp);
});


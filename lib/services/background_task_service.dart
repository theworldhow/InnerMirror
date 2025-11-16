import 'dart:async';
import 'package:workmanager/workmanager.dart' as workmanager;
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'data_ingestion_service.dart';
import 'embedding_service.dart';
import 'mirror_generation_service.dart';
import 'lora_fine_tuning_service.dart';
import 'push_notification_service.dart';
import 'future_you_voice_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  workmanager.Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'nightly_ingestion':
          await _runIngestion();
          break;
        case 'morning_mirrors':
          await _runMirrorGeneration();
          break;
        case 'daily_notification':
          await _scheduleDailyNotification();
          break;
        case 'sunday_voice':
          await _generateFutureYouVoice();
          break;
      }
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  try {
    await _runIngestion();
    BackgroundFetch.finish(task.taskId);
  } catch (e) {
    BackgroundFetch.finish(task.taskId);
  }
}

Future<void> _runIngestion() async {
  final ingestion = DataIngestionService.instance;
  await ingestion.ingestAll();
  
  final embedding = EmbeddingService.instance;
  await embedding.reindexAll();
  
  // Run LoRA fine-tuning after ingestion
  final lora = LoRAFineTuningService.instance;
  await lora.fineTuneNightly();
}

Future<void> _runMirrorGeneration() async {
  final mirrorGen = MirrorGenerationService.instance;
  await mirrorGen.generateAllMirrors();
}

Future<void> _scheduleDailyNotification() async {
  final pushService = PushNotificationService.instance;
  await pushService.sendDailyNotification();
}

Future<void> _generateFutureYouVoice() async {
  final voiceService = FutureYouVoiceService.instance;
  await voiceService.generateWeeklyMessage();
}

class BackgroundTaskService {
  static BackgroundTaskService? _instance;
  static BackgroundTaskService get instance => _instance ??= BackgroundTaskService._();
  
  BackgroundTaskService._();

  Future<void> initialize() async {
    // Android: WorkManager (iOS uses Background Fetch instead)
    if (kDebugMode) {
      print('[BackgroundTaskService] Initializing...');
    }
    
    // Only initialize WorkManager on Android
    // iOS will use BackgroundFetch.configure below
    try {
      await workmanager.Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Schedule daily task at 3:01 AM with 15-minute flex (Android only)
      await workmanager.Workmanager().registerPeriodicTask(
        'nightly_ingestion',
        'nightly_ingestion',
        frequency: const Duration(hours: 24),
        initialDelay: _getInitialDelay(3, 1),
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      // Schedule mirror generation at 8:00 AM (Android only)
      await workmanager.Workmanager().registerPeriodicTask(
        'morning_mirrors',
        'morning_mirrors',
        frequency: const Duration(hours: 24),
        initialDelay: _getInitialDelay(8, 0),
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      // Schedule daily notification at 9:00 AM (Android only)
      await workmanager.Workmanager().registerPeriodicTask(
        'daily_notification',
        'daily_notification',
        frequency: const Duration(hours: 24),
        initialDelay: _getInitialDelay(9, 0),
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      // Schedule Future You voice message every Sunday at 8:00 AM (Android only)
      await workmanager.Workmanager().registerPeriodicTask(
        'sunday_voice',
        'sunday_voice',
        frequency: const Duration(days: 7),
        initialDelay: _getNextSundayDelay(),
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      
      if (kDebugMode) {
        print('[BackgroundTaskService] WorkManager tasks registered (Android)');
      }
    } catch (e) {
      // WorkManager not available (likely iOS) - this is expected
      if (kDebugMode) {
        print('[BackgroundTaskService] WorkManager not available (iOS): $e');
      }
    }

    // iOS: Background Fetch
    try {
      BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15, // minutes
          stopOnTerminate: false,
          enableHeadless: true,
          startOnBoot: true,
          requiredNetworkType: NetworkType.NONE,
        ),
        backgroundFetchHeadlessTask,
      ).then((status) {
        if (kDebugMode) {
          print('[BackgroundFetch] configure success: $status');
        }
      }).catchError((e) {
        if (kDebugMode) {
          print('[BackgroundFetch] configure ERROR: $e');
        }
      });
    } catch (e) {
      // BackgroundFetch might not be available - this is okay
      if (kDebugMode) {
        print('[BackgroundTaskService] BackgroundFetch not available: $e');
      }
    }
    
    if (kDebugMode) {
      print('[BackgroundTaskService] Initialization complete');
    }
  }

  Duration _getInitialDelay(int hour, int minute) {
    final now = DateTime.now();
    var nextRun = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (nextRun.isBefore(now)) {
      nextRun = nextRun.add(const Duration(days: 1));
    }
    
    return nextRun.difference(now);
  }

  Duration _getNextSundayDelay() {
    final now = DateTime.now();
    var nextSunday = now;
    
    // Find next Sunday
    while (nextSunday.weekday != DateTime.sunday) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }
    
    // Set to 8:00 AM
    nextSunday = DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 8, 0);
    
    // If it's already past 8 AM today and today is Sunday, schedule for next Sunday
    if (now.weekday == DateTime.sunday && now.hour >= 8) {
      nextSunday = nextSunday.add(const Duration(days: 7));
    }
    
    return nextSunday.difference(now);
  }

  Future<void> runNow() async {
    await _runIngestion();
  }
}


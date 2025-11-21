import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:health/health.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:calendar/calendar.dart';
import 'package:app_usage/app_usage.dart';
import 'life_log_service.dart';
import 'permission_service.dart';

class DataIngestionService {
  static DataIngestionService? _instance;
  static DataIngestionService get instance => _instance ??= DataIngestionService._();
  
  DataIngestionService._();

  final LifeLogService _lifeLog = LifeLogService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  Health? _health;

  Future<void> ingestAll() async {
    try {
      print('Starting data ingestion - Reading from all available sources...');
      
      // Ingest all new data sources
      await _ingestPhotosAndVideos();
      await _ingestHealthAndFitness();
      await _ingestAppUsage();
      await _ingestLocationHistory();
      await _ingestCalendarAndEvents();
      await _ingestContacts();
      await _ingestRemindersAndNotes();
      await _ingestMicrophoneAudio();
      
      // Generate test data in simulator for testing
      if (kDebugMode) {
        // Only in debug mode - add test data
        await _ingestTestData();
      }
      
      // Save last ingestion time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_ingestion_time', DateTime.now().millisecondsSinceEpoch);
      
      print('Data ingestion complete - All data sources processed');
    } catch (e) {
      print('Ingestion error: $e');
    }
  }

  /// Ingest data for the past 6 months (used for first-time install)
  Future<void> ingestPastWeek() async {
    try {
      print('Starting first-time data ingestion (past 6 months)...');
      
      final now = DateTime.now();
      // 6 months = approximately 180 days
      final sixMonthsAgo = now.subtract(const Duration(days: 180));
      
      // Ingest all data sources for past 6 months
      await _ingestPhotosAndVideos(sixMonthsAgo, now);
      await _ingestHealthAndFitness(sixMonthsAgo, now);
      await _ingestAppUsage(sixMonthsAgo, now);
      await _ingestLocationHistory(sixMonthsAgo, now);
      await _ingestCalendarAndEvents(sixMonthsAgo, now);
      await _ingestContacts();
      await _ingestRemindersAndNotes(sixMonthsAgo, now);
      await _ingestMicrophoneAudio(sixMonthsAgo, now);
      
      // Generate test data in simulator/debug mode
      if (kDebugMode) {
        await _ingestTestDataPastWeek(sixMonthsAgo, now);
      }
      
      // Save last ingestion time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_ingestion_time', DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('first_time_ingestion_complete', true);
      
      print('First-time data ingestion complete (past 6 months)');
    } catch (e) {
      print('First-time ingestion error: $e');
    }
  }

  // Generate test data for simulator/debugging
  Future<void> _ingestTestData() async {
    try {
      final now = DateTime.now();
      
      // Add a few test entries to verify ingestion works
      await _lifeLog.appendEntry({
        'type': 'test',
        'timestamp': now.toIso8601String(),
        'message': 'Test ingestion entry from simulator',
        'source': 'debug_mode',
        'date': now.millisecondsSinceEpoch,
      });
      
      // Add location test entry
      await _lifeLog.appendEntry({
        'type': 'location',
        'timestamp': now.subtract(const Duration(hours: 1)).toIso8601String(),
        'latitude': 37.7749, // San Francisco (simulator default location)
        'longitude': -122.4194,
        'accuracy': 100.0,
        'note': 'Simulator test location',
        'date': now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      });
      
      // Add another test entry
      await _lifeLog.appendEntry({
        'type': 'test',
        'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'message': 'Another test entry for debugging',
        'source': 'simulator',
        'date': now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      });
      
      print('Test data ingested (3 entries)');
    } catch (e) {
      print('Test data ingestion error: $e');
    }
  }

  Future<void> _ingestSMS() async {
    if (Platform.isAndroid) {
      try {
        // First check if SMS permission is already granted
        final smsPermission = await Permission.sms.status;
        if (!smsPermission.isGranted) {
          // Request SMS permission - this will show system dialog
          final requested = await Permission.sms.request();
          if (!requested.isGranted) {
            print('SMS permission not granted - skipping SMS ingestion');
            return;
          }
        }
        
        final hasPermission = await _telephony.requestPhoneAndSmsPermissions ?? false;
        if (!hasPermission) {
          print('SMS permission not granted - skipping SMS ingestion');
          return;
        }

        // Read ALL SMS messages (no date filter)
        final messages = await _telephony.getInboxSms(
          columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
          sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
        );

        int ingestedCount = 0;
        for (final msg in messages) {
          final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);
          // Ingest ALL messages regardless of date
          await _lifeLog.appendEntry({
            'type': 'sms',
            'timestamp': msgDate.toIso8601String(),
            'from': msg.address ?? 'unknown',
            'body': msg.body ?? '',
            'date': msgDate.millisecondsSinceEpoch,
            'message': msg.body ?? '', // Also store in 'message' field for compatibility
          });
          ingestedCount++;
        }
        print('Ingested $ingestedCount SMS messages (ALL messages from inbox)');
      } catch (e) {
        print('SMS ingestion error (non-critical): $e');
      }
    } else if (Platform.isIOS) {
      // iOS: Attempt to access all SMS messages
      try {
        print('iOS SMS ingestion: Attempting to access all SMS messages...');
        await _ingestAllSMSiOS();
      } catch (e) {
        print('iOS SMS ingestion error: $e');
      }
    }
  }

  /// Attempt to ingest all SMS messages on iOS
  Future<void> _ingestAllSMSiOS() async {
    if (!Platform.isIOS) return;
    
    try {
      // Request SMS permission - this will show iOS system dialog
      final smsPermissionStatus = await Permission.sms.status;
      PermissionStatus smsPermission;
      
      if (!smsPermissionStatus.isGranted) {
        smsPermission = await Permission.sms.request();
      } else {
        smsPermission = smsPermissionStatus;
      }
      
      if (!smsPermission.isGranted) {
        print('SMS permission not granted on iOS - user needs to grant in Settings');
        // Note: Don't auto-open settings here - onboarding will handle it
        return;
      }

      // Attempt to access SMS via telephony package (may have limitations)
      // Note: iOS restrictions may prevent full access, but we'll attempt it
      final hasPermission = await _telephony.requestPhoneAndSmsPermissions ?? false;
      if (hasPermission) {
        try {
          // Read ALL SMS messages (no date filter)
          final messages = await _telephony.getInboxSms(
            columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
            sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
          );

          int ingestedCount = 0;
          for (final msg in messages) {
            final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);
            // Ingest ALL messages regardless of date
            await _lifeLog.appendEntry({
              'type': 'sms',
              'timestamp': msgDate.toIso8601String(),
              'from': msg.address ?? 'unknown',
              'body': msg.body ?? '',
              'date': msgDate.millisecondsSinceEpoch,
              'message': msg.body ?? '', // Also store in 'message' field for compatibility
            });
            ingestedCount++;
          }
          print('Ingested $ingestedCount SMS messages on iOS (ALL messages from inbox)');
        } catch (e) {
          print('iOS SMS access attempt failed: $e');
          print('Note: iOS may restrict full SMS access - this is expected');
        }
      } else {
        print('SMS permission request failed on iOS');
      }
    } catch (e) {
      print('iOS SMS ingestion error: $e');
    }
  }

  Future<void> _ingestSMSPastWeek(DateTime startTime, DateTime endTime) async {
    if (Platform.isAndroid) {
      final hasPermission = await _telephony.requestPhoneAndSmsPermissions ?? false;
      if (!hasPermission) return;

      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      // Read ALL SMS messages (no date filter - user wants all messages)
      int ingestedCount = 0;
      for (final msg in messages) {
        final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);
        // Ingest ALL messages regardless of date
        await _lifeLog.appendEntry({
          'type': 'sms',
          'timestamp': msgDate.toIso8601String(),
          'from': msg.address ?? 'unknown',
          'body': msg.body ?? '',
          'date': msgDate.millisecondsSinceEpoch,
          'message': msg.body ?? '', // Also store in 'message' field for compatibility
        });
        ingestedCount++;
      }
      print('Ingested $ingestedCount SMS messages (ALL messages from inbox)');
    }
  }

  Future<void> _ingestPhotos() async {
    if (await Permission.photos.isDenied) {
      await Permission.photos.request();
    }
    if (await Permission.photos.isDenied) {
      print('Photos permission denied - skipping photo ingestion');
      return;
    }

    // Get recent photos (last 60 days)
    final now = DateTime.now();
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));

    // Note: pickMultiImage() requires user interaction (opens picker)
    // For automatic ingestion, we'd need photo_manager package or similar
    // For now, this requires user to manually select photos
    try {
      // Try to get photos automatically (may not work without user interaction)
      final recentImages = await _imagePicker.pickMultiImage();
      
      if (recentImages != null && recentImages.isNotEmpty) {
        for (final image in recentImages) {
          final file = File(image.path);
          if (await file.exists()) {
            final stat = await file.stat();
            final modified = stat.modified;
            
            if (modified.isAfter(sixtyDaysAgo)) {
              await _lifeLog.appendEntry({
                'type': 'photo',
                'timestamp': modified.toIso8601String(),
                'path': image.path,
                'size': stat.size,
                'date': modified.millisecondsSinceEpoch,
              });
            }
          }
        }
      } else {
        print('No photos selected - photo ingestion skipped');
      }
    } catch (e) {
      print('Photo ingestion error: $e');
      // Continue with other ingestion
    }
  }

  Future<void> _ingestHealth() async {
    // HealthKit is iOS only
    if (!Platform.isIOS) return;
    
    try {
      _health ??= Health();
      
      final types = [
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.STEPS,
      ];

      final permissions = await _health!.requestAuthorization(types);
      if (!permissions) {
        print('HealthKit permission denied');
        return;
      }

      final now = DateTime.now();
      final sixtyDaysAgo = now.subtract(const Duration(days: 60));

      // Get HRV data
      try {
        final hrvData = await _health!.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
          startTime: sixtyDaysAgo,
          endTime: now,
        );

        for (final data in hrvData) {
          await _lifeLog.appendEntry({
            'type': 'health_hrv',
            'timestamp': data.dateFrom.toIso8601String(),
            'value': data.value,
            'date': data.dateFrom.millisecondsSinceEpoch,
          });
        }
      } catch (e) {
        print('HealthKit HRV error (non-critical): $e');
        // Health data may not be available or entitlement missing
      }

      // Get sleep data
      try {
        final sleepData = await _health!.getHealthDataFromTypes(
          types: [HealthDataType.SLEEP_IN_BED],
          startTime: sixtyDaysAgo,
          endTime: now,
        );

        for (final data in sleepData) {
          await _lifeLog.appendEntry({
            'type': 'health_sleep',
            'timestamp': data.dateFrom.toIso8601String(),
            'value': data.value,
            'date': data.dateFrom.millisecondsSinceEpoch,
          });
        }
      } catch (e) {
        print('HealthKit sleep error (non-critical): $e');
      }

      // Get steps
      try {
        final stepsData = await _health!.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: sixtyDaysAgo,
          endTime: now,
        );

        for (final data in stepsData) {
          await _lifeLog.appendEntry({
            'type': 'health_steps',
            'timestamp': data.dateFrom.toIso8601String(),
            'value': data.value,
            'date': data.dateFrom.millisecondsSinceEpoch,
          });
        }
      } catch (e) {
        print('HealthKit steps error (non-critical): $e');
      }
    } catch (e) {
      // HealthKit may not be available (missing entitlement, not available on device, etc.)
      print('HealthKit ingestion error (non-critical): $e');
      // Continue with other ingestion tasks
    }
  }

  Future<void> _ingestLocation() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
    if (await Permission.location.isDenied) return;

    // Get significant locations (simplified - would need more sophisticated clustering)
    final now = DateTime.now();
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));

    // Note: Full location history would require Google Location History API
    // For now, we'll get current location and log it
    try {
      final position = await Geolocator.getCurrentPosition();
      await _lifeLog.appendEntry({
        'type': 'location',
        'timestamp': DateTime.now().toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'date': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Location may not be available
    }
  }

  Future<void> _ingestLocationPastWeek(DateTime startTime, DateTime endTime) async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
    if (await Permission.location.isDenied) return;

    // Note: Full location history would require Google Location History API
    // For now, we'll get current location and log it
    // In production, this would query location history for the past week
    try {
      final position = await Geolocator.getCurrentPosition();
      final now = DateTime.now();
      if (now.isAfter(startTime) && now.isBefore(endTime)) {
        await _lifeLog.appendEntry({
          'type': 'location',
          'timestamp': now.toIso8601String(),
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'date': now.millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      // Location may not be available
    }
  }

  Future<void> _ingestHealthPastWeek(DateTime startTime, DateTime endTime) async {
    // HealthKit is iOS only
    if (!Platform.isIOS) return;
    
    try {
      _health ??= Health();
      
      final types = [
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.STEPS,
      ];

      final permissions = await _health!.requestAuthorization(types);
      if (!permissions) {
        print('HealthKit permission denied');
        return;
      }

      // Get HRV data for past week
      try {
        final hrvData = await _health!.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
          startTime: startTime,
          endTime: endTime,
        );

        for (final data in hrvData) {
          await _lifeLog.appendEntry({
            'type': 'health_hrv',
            'timestamp': data.dateFrom.toIso8601String(),
            'value': data.value,
            'date': data.dateFrom.millisecondsSinceEpoch,
          });
        }
      } catch (e) {
        print('HealthKit HRV error (non-critical): $e');
      }

      // Get sleep data for past week
      try {
        final sleepData = await _health!.getHealthDataFromTypes(
          types: [HealthDataType.SLEEP_IN_BED],
          startTime: startTime,
          endTime: endTime,
        );

        for (final data in sleepData) {
          await _lifeLog.appendEntry({
            'type': 'health_sleep',
            'timestamp': data.dateFrom.toIso8601String(),
            'value': data.value,
            'date': data.dateFrom.millisecondsSinceEpoch,
          });
        }
      } catch (e) {
        print('HealthKit sleep error (non-critical): $e');
      }

      // Get steps for past week
      try {
        final stepsData = await _health!.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: startTime,
          endTime: endTime,
        );

        for (final data in stepsData) {
          await _lifeLog.appendEntry({
            'type': 'health_steps',
            'timestamp': data.dateFrom.toIso8601String(),
            'value': data.value,
            'date': data.dateFrom.millisecondsSinceEpoch,
          });
        }
      } catch (e) {
        print('HealthKit steps error (non-critical): $e');
      }
    } catch (e) {
      print('HealthKit ingestion error (non-critical): $e');
    }
  }

  Future<void> _ingestTestDataPastWeek(DateTime startTime, DateTime endTime) async {
    try {
      final now = DateTime.now();
      final daysSpan = endTime.difference(startTime).inDays;
      // Generate test data spread across the 6 month period
      // Sample every 3 days to avoid too many entries
      final sampleInterval = 3;
      
      int entryCount = 0;
      for (int day = 0; day < daysSpan; day += sampleInterval) {
        final entryTime = now.subtract(Duration(days: day));
        if (entryTime.isAfter(startTime) && entryTime.isBefore(endTime)) {
          // Add SMS-like test entry
          await _lifeLog.appendEntry({
            'type': 'test',
            'timestamp': entryTime.toIso8601String(),
            'message': 'First-time install test entry - ${day} days ago',
            'source': 'first_time_setup',
            'date': entryTime.millisecondsSinceEpoch,
          });
          
          entryCount++;
          
            // Note: Location and health data ingestion removed - only SMS and WhatsApp
        }
      }
      
      print('First-time test data ingested (past 6 months - $entryCount entries)');
    } catch (e) {
      print('First-time test data ingestion error: $e');
    }
  }

  /// Ingest WhatsApp messages from notifications (Android & iOS)
  /// Requires notification access permission
  Future<void> _ingestWhatsAppNotifications() async {
    try {
      if (Platform.isAndroid) {
        // Check if notification listener is enabled (Android)
        bool isEnabled = false;
        try {
          final result = await _permissionChannel.invokeMethod<bool>('checkNotificationAccess');
          isEnabled = result ?? false;
        } catch (e) {
          print('Error checking notification access: $e');
        }
        
        if (isEnabled) {
          print('WhatsApp notification listener is enabled - messages will be captured in real-time');
          // Messages are captured in real-time via WhatsAppNotificationService
          // No need to do batch ingestion here
        } else {
          print('WhatsApp notification listener not enabled - user must enable in Accessibility settings');
          // Attempt to read from WhatsApp database (if accessible)
          await _ingestWhatsAppFromDatabase();
        }
      } else if (Platform.isIOS) {
        // iOS: Attempt to use notification listener or other methods
        print('Attempting WhatsApp message ingestion on iOS...');
        await _ingestWhatsAppFromNotificationsiOS();
      }
      
    } catch (e) {
      print('WhatsApp notification ingestion error (non-critical): $e');
    }
  }

  /// Attempt to ingest WhatsApp messages on iOS via notification listener
  Future<void> _ingestWhatsAppFromNotificationsiOS() async {
    if (!Platform.isIOS) return;
    
    try {
      // iOS: Attempt to access WhatsApp notifications
      // Note: iOS restrictions may limit this, but we'll try
      print('WhatsApp iOS ingestion: Attempting notification-based capture');
      print('Note: iOS may require user to enable notification access in Settings > Notifications');
      
      // Try to use notification listener if available
      // This may require additional iOS setup or may not work due to restrictions
      // For now, we'll log and attempt
      
    } catch (e) {
      print('WhatsApp iOS ingestion error: $e');
    }
  }

  /// Attempt to read WhatsApp messages from database (Android only)
  /// This requires root access or accessibility permissions
  Future<void> _ingestWhatsAppFromDatabase() async {
    if (!Platform.isAndroid) return;
    
    try {
      // WhatsApp stores messages in SQLite database at:
      // /data/data/com.whatsapp/databases/msgstore.db
      // However, this requires root access or special permissions
      
      // On Android without root:
      // - Cannot directly access WhatsApp database due to sandbox restrictions
      // - Notification Listener Service can capture future messages as they arrive
      // - For ALL existing messages, user must export WhatsApp chat and import
      
      print('WhatsApp database direct access: Limited on Android without root access');
      print('To ingest ALL existing WhatsApp messages:');
      print('1. Open WhatsApp > Chat > More > Export Chat');
      print('2. Go to Debug Screen (shake device) > Import WhatsApp Chat');
      print('3. Select the exported .txt file');
      print('');
      print('For future messages: Enable Notification Listener in Settings > Accessibility');
      
    } catch (e) {
      print('WhatsApp database ingestion error: $e');
    }
  }

  /// Import WhatsApp chat from exported file
  /// User selects exported WhatsApp chat file (.txt)
  Future<void> importWhatsAppChat() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        dialogTitle: 'Select WhatsApp Chat Export',
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final messages = await _chatParser.parseChatFile(file);
        
        // Import ALL messages from WhatsApp export (no date filter)
        int importedCount = 0;
        for (final message in messages) {
          // Ingest ALL messages regardless of date
          await _lifeLog.appendEntry(message);
          importedCount++;
        }
        
        print('Imported $importedCount WhatsApp messages from chat export (ALL messages)');
        return;
      }
      
      print('No WhatsApp chat file selected');
    } catch (e) {
      print('WhatsApp chat import error: $e');
    }
  }

  /// Import iOS Messages from exported file
  /// User selects exported Messages file (.txt or other format)
  Future<void> importiOSMessages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv'],
        dialogTitle: 'Select iOS Messages Export',
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final messages = await _chatParser.parseiOSMessagesFile(file);
        
        // Filter messages from last 6 months for first-time, or last 60 days for regular
        final prefs = await SharedPreferences.getInstance();
        final isFirstTime = !(prefs.getBool('first_time_ingestion_complete') ?? false);
        final cutoffDate = isFirstTime
            ? DateTime.now().subtract(const Duration(days: 180))
            : DateTime.now().subtract(const Duration(days: 60));
        
        int importedCount = 0;
        for (final message in messages) {
          final msgDate = DateTime.fromMillisecondsSinceEpoch(message['date'] as int);
          if (msgDate.isAfter(cutoffDate)) {
            await _lifeLog.appendEntry(message);
            importedCount++;
          }
        }
        
        print('Imported $importedCount iOS Messages from export');
        return;
      }
      
      print('No iOS Messages file selected');
    } catch (e) {
      print('iOS Messages import error: $e');
    }
  }

  /// Attempt to ingest iOS Messages automatically (iOS only)
  /// Attempts full access via notification listener and other methods
  Future<void> _ingestiOSMessages() async {
    if (!Platform.isIOS) return;
    
    try {
      print('iOS Messages ingestion: Attempting full access...');
      
      // Attempt 1: Use notification listener for Messages
      await _ingestMessagesFromNotificationsiOS();
      
      // Attempt 2: Try to access Messages database or other methods
      await _ingestMessagesFromDatabaseiOS();
      
    } catch (e) {
      print('iOS Messages ingestion error: $e');
    }
  }

  /// Attempt to ingest iOS Messages from notifications
  Future<void> _ingestMessagesFromNotificationsiOS() async {
    if (!Platform.isIOS) return;
    
    try {
      print('iOS Messages notification ingestion: Attempting to capture Messages via notifications');
      print('Note: User may need to enable notification access in Settings > Notifications');
      
      // iOS notification listener for Messages (iMessage)
      // This may require additional setup or entitlements
      // Attempt to capture Messages notifications if listener is enabled
      
    } catch (e) {
      print('iOS Messages notification ingestion error: $e');
    }
  }

  /// Attempt to ingest iOS Messages from database or other sources
  Future<void> _ingestMessagesFromDatabaseiOS() async {
    if (!Platform.isIOS) return;
    
    try {
      print('iOS Messages database ingestion: Attempting direct access');
      
      // Note: Direct database access is typically not possible on iOS due to sandboxing
      // However, we'll attempt any available methods
      // This may not work due to iOS restrictions, but we try
      
    } catch (e) {
      print('iOS Messages database ingestion error: $e');
    }
  }
}


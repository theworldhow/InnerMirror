import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'package:image_picker/image_picker.dart';
import 'package:health/health.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'life_log_service.dart';

class DataIngestionService {
  static DataIngestionService? _instance;
  static DataIngestionService get instance => _instance ??= DataIngestionService._();
  
  DataIngestionService._();

  final LifeLogService _lifeLog = LifeLogService.instance;
  final Telephony _telephony = Telephony.instance;
  final ImagePicker _imagePicker = ImagePicker();
  Health? _health;

  Future<void> ingestAll() async {
    try {
      print('Starting data ingestion...');
      
      // Ingest in order (most reliable first)
      await _ingestLocation(); // Usually works if permission granted
      await _ingestHealth(); // May not work in simulator
      await _ingestSMS(); // Only Android
      
      // Photos requires user interaction (picker dialog)
      // Skip automatic photo ingestion - requires manual selection
      // await _ingestPhotos(); // Commented out - requires user interaction
      
      // Generate test data in simulator for testing
      if (kDebugMode) {
        // Only in debug mode - add test data
        await _ingestTestData();
      }
      
      // Save last ingestion time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_ingestion_time', DateTime.now().millisecondsSinceEpoch);
      
      print('Data ingestion complete');
    } catch (e) {
      print('Ingestion error: $e');
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
      final hasPermission = await _telephony.requestPhoneAndSmsPermissions ?? false;
      if (!hasPermission) return;

      final now = DateTime.now();
      final sixtyDaysAgo = now.subtract(const Duration(days: 60));
      
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      for (final msg in messages) {
        final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);
        if (msgDate.isAfter(sixtyDaysAgo)) {
          await _lifeLog.appendEntry({
            'type': 'sms',
            'timestamp': msgDate.toIso8601String(),
            'from': msg.address ?? 'unknown',
            'body': msg.body ?? '',
            'date': msgDate.millisecondsSinceEpoch,
          });
        }
      }
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
}


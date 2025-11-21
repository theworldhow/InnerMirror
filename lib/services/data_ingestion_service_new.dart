import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:health/health.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contacts_service/contacts_service.dart';
import 'life_log_service.dart';
import 'permission_service.dart';

class DataIngestionService {
  static DataIngestionService? _instance;
  static DataIngestionService get instance => _instance ??= DataIngestionService._();
  
  DataIngestionService._();

  final LifeLogService _lifeLog = LifeLogService.instance;
  Health? _health;

  Future<void> ingestAll() async {
    try {
      print('Starting data ingestion from all available sources...');
      
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

  // ========== PHOTOS & VIDEOS ==========
  Future<void> _ingestPhotosAndVideos([DateTime? startTime, DateTime? endTime]) async {
    try {
      if (await Permission.photos.isDenied) {
        await Permission.photos.request();
      }
      if (await Permission.photos.isDenied) {
        print('Photos permission denied - skipping photo ingestion');
        return;
      }

      // Request photo library access
      final result = await PhotoManager.requestPermissionExtend();
      if (!result.isAuth) {
        print('Photo library access denied');
        return;
      }

      final now = DateTime.now();
      final start = startTime ?? now.subtract(const Duration(days: 60));
      final end = endTime ?? now;

      // Get all albums
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.all,
        hasAll: true,
      );

      int ingestedCount = 0;
      for (final album in albums) {
        // Get assets from album within date range
        final assets = await album.getAssetListRange(
          start: 0,
          end: await album.assetCountAsync,
        );

        for (final asset in assets) {
          final createTime = asset.createDateTime;
          if (createTime.isAfter(start) && createTime.isBefore(end)) {
            // Get metadata
            final lat = asset.latitude;
            final lng = asset.longitude;
            
            // Get thumbnail
            final thumbnail = await asset.thumbnailDataWithSize(
              const ThumbnailSize(200, 200),
            );

            await _lifeLog.appendEntry({
              'type': 'photo',
              'timestamp': createTime.toIso8601String(),
              'date': createTime.millisecondsSinceEpoch,
              'latitude': lat,
              'longitude': lng,
              'width': asset.width,
              'height': asset.height,
              'duration': asset.duration, // For videos
              'isVideo': asset.type == AssetType.video,
              'title': asset.title,
              'subtype': asset.subtype.toString(),
              'thumbnailSize': thumbnail?.length ?? 0,
            });
            ingestedCount++;
          }
        }
      }
      print('Ingested $ingestedCount photos/videos');
    } catch (e) {
      print('Photos/Videos ingestion error: $e');
    }
  }

  // ========== HEALTH & FITNESS ==========
  Future<void> _ingestHealthAndFitness([DateTime? startTime, DateTime? endTime]) async {
    if (!Platform.isIOS) {
      // Android: Use Google Fit or similar
      print('Health data ingestion: Android support coming soon');
      return;
    }
    
    try {
      _health ??= Health();
      
      final now = DateTime.now();
      final start = startTime ?? now.subtract(const Duration(days: 60));
      final end = endTime ?? now;

      final types = [
        HealthDataType.STEPS,
        HealthDataType.WORKOUT,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.MINDFULNESS,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
      ];

      // iOS 18+ mood/depression risk scores
      if (Platform.isIOS) {
        try {
          types.add(HealthDataType.DEPRESSION_RISK_SCORE);
        } catch (e) {
          // May not be available on older iOS versions
        }
      }

      final permissions = await _health!.requestAuthorization(types);
      if (!permissions) {
        print('HealthKit permission denied');
        return;
      }

      int ingestedCount = 0;
      for (final type in types) {
        try {
          final data = await _health!.getHealthDataFromTypes(
            types: [type],
            startTime: start,
            endTime: end,
          );

          for (final entry in data) {
            await _lifeLog.appendEntry({
              'type': 'health_${type.name}',
              'timestamp': entry.dateFrom.toIso8601String(),
              'date': entry.dateFrom.millisecondsSinceEpoch,
              'value': entry.value,
              'unit': entry.unit,
              'dateTo': entry.dateTo?.toIso8601String(),
            });
            ingestedCount++;
          }
        } catch (e) {
          print('Health data type $type error: $e');
        }
      }
      print('Ingested $ingestedCount health/fitness entries');
    } catch (e) {
      print('Health/Fitness ingestion error: $e');
    }
  }

  // ========== APP USAGE & SCREEN TIME ==========
  Future<void> _ingestAppUsage([DateTime? startTime, DateTime? endTime]) async {
    try {
      // Request usage access permission
      if (Platform.isAndroid) {
        // Android: Usage Stats permission
        final permission = await Permission.appTrackingTransparency.status;
        // Note: app_usage package handles its own permissions
      }

      final now = DateTime.now();
      final start = startTime ?? now.subtract(const Duration(days: 7));
      final end = endTime ?? now;

      // Note: app_usage package implementation
      // This requires native setup for both iOS and Android
      print('App Usage ingestion: Requires native implementation');
      print('Will track: daily/weekly usage, pickups, notifications (aggregate trends)');
      
      // Placeholder for app usage data
      // In production, use app_usage package to get:
      // - Daily/weekly app usage duration
      // - Device pickups
      // - Notifications received (aggregate)
      
    } catch (e) {
      print('App Usage ingestion error: $e');
    }
  }

  // ========== LOCATION HISTORY ==========
  Future<void> _ingestLocationHistory([DateTime? startTime, DateTime? endTime]) async {
    try {
      if (await Permission.location.isDenied) {
        await Permission.location.request();
      }
      if (await Permission.location.isDenied) {
        print('Location permission denied - skipping location ingestion');
        return;
      }

      final now = DateTime.now();
      final start = startTime ?? now.subtract(const Duration(days: 60));
      final end = endTime ?? now;

      // Get location history
      // Note: Full history requires Google Location History (Android) or 
      // Significant Locations (iOS) - both require additional setup
      
      // For now, get current location and significant locations
      try {
        // Get current position
        final position = await Geolocator.getCurrentPosition();
        await _lifeLog.appendEntry({
          'type': 'location',
          'timestamp': now.toIso8601String(),
          'date': now.millisecondsSinceEpoch,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'speed': position.speed,
          'heading': position.heading,
        });

        // Get last known position
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          await _lifeLog.appendEntry({
            'type': 'location',
            'timestamp': now.subtract(const Duration(hours: 1)).toIso8601String(),
            'date': now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
            'latitude': lastPosition.latitude,
            'longitude': lastPosition.longitude,
            'accuracy': lastPosition.accuracy,
          });
        }

        // Note: For full location history, implement:
        // - Android: Google Location History API
        // - iOS: Significant Locations (requires additional entitlements)
        // - Geofenced events tracking
        
        print('Location history ingestion: Basic location captured');
      } catch (e) {
        print('Location ingestion error: $e');
      }
    } catch (e) {
      print('Location history ingestion error: $e');
    }
  }

  // ========== CALENDAR & EVENTS ==========
  Future<void> _ingestCalendarAndEvents([DateTime? startTime, DateTime? endTime]) async {
    try {
      // Request calendar permission
      if (Platform.isIOS) {
        final permission = await Permission.calendar.status;
        if (!permission.isGranted) {
          await Permission.calendar.request();
        }
        if (!permission.isGranted) {
          print('Calendar permission denied');
          return;
        }
      } else if (Platform.isAndroid) {
        final permission = await Permission.calendar.status;
        if (!permission.isGranted) {
          await Permission.calendar.request();
        }
        if (!permission.isGranted) {
          print('Calendar permission denied');
          return;
        }
      }

      final now = DateTime.now();
      final start = startTime ?? now.subtract(const Duration(days: 60));
      final end = endTime ?? now;

      // Note: calendar package implementation
      // Get events within date range
      print('Calendar ingestion: Requires calendar package implementation');
      print('Will capture: event titles, descriptions, attendees, locations, dates, recurring patterns');
      
      // Placeholder - implement with calendar package
      // For each event:
      // - Title, description
      // - Attendees
      // - Location
      // - Start/end dates
      // - Recurring pattern detection
      
    } catch (e) {
      print('Calendar/Events ingestion error: $e');
    }
  }

  // ========== CONTACTS ==========
  Future<void> _ingestContacts() async {
    try {
      // Request contacts permission
      if (await Permission.contacts.isDenied) {
        await Permission.contacts.request();
      }
      if (await Permission.contacts.isDenied) {
        print('Contacts permission denied - skipping contacts ingestion');
        return;
      }

      // Get all contacts
      final contacts = await ContactsService.getContacts();
      
      int ingestedCount = 0;
      for (final contact in contacts) {
        await _lifeLog.appendEntry({
          'type': 'contact',
          'timestamp': DateTime.now().toIso8601String(),
          'date': DateTime.now().millisecondsSinceEpoch,
          'name': contact.displayName ?? '',
          'givenName': contact.givenName ?? '',
          'familyName': contact.familyName ?? '',
          'emails': contact.emails?.map((e) => e.value).toList() ?? [],
          'phones': contact.phones?.map((p) => p.value).toList() ?? [],
          'notes': contact.notes?.map((n) => n.value).join(' ') ?? '',
          'company': contact.company ?? '',
          'jobTitle': contact.jobTitle ?? '',
        });
        ingestedCount++;
      }
      print('Ingested $ingestedCount contacts');
    } catch (e) {
      print('Contacts ingestion error: $e');
    }
  }

  // ========== REMINDERS & NOTES ==========
  Future<void> _ingestRemindersAndNotes([DateTime? startTime, DateTime? endTime]) async {
    try {
      // Request reminders permission (iOS)
      if (Platform.isIOS) {
        // iOS Reminders access
        print('Reminders ingestion: iOS Reminders access');
        // Note: Requires EventKit framework integration
      }

      final now = DateTime.now();
      final start = startTime ?? now.subtract(const Duration(days: 60));
      final end = endTime ?? now;

      // Note: Reminders & Notes require native implementation
      // iOS: EventKit framework for Reminders
      // Notes: iOS Notes app access is restricted
      print('Reminders/Notes ingestion: Requires native implementation');
      print('Will capture: task lists, due dates, notes content');
      
      // Placeholder for reminders and notes
      // In production, implement:
      // - iOS: EventKit for Reminders
      // - Notes: May require manual export/import
      
    } catch (e) {
      print('Reminders/Notes ingestion error: $e');
    }
  }

  // ========== MICROPHONE/AUDIO ==========
  Future<void> _ingestMicrophoneAudio([DateTime? startTime, DateTime? endTime]) async {
    try {
      // Request microphone permission
      if (await Permission.microphone.isDenied) {
        await Permission.microphone.request();
      }
      if (await Permission.microphone.isDenied) {
        print('Microphone permission denied - skipping audio ingestion');
        return;
      }

      // Note: Microphone audio ingestion
      // This is for real-time audio input or user-recorded clips
      // Implementation depends on how audio is captured:
      // - Real-time: Use speech_to_text package (already in pubspec)
      // - Recorded clips: Store audio files and metadata
      
      print('Microphone/Audio ingestion: Ready for audio input');
      print('Will capture: real-time audio input or user-recorded voice clips');
      
      // Placeholder - audio ingestion happens when user records
      // Store metadata about recorded audio clips
      
    } catch (e) {
      print('Microphone/Audio ingestion error: $e');
    }
  }

  // ========== TEST DATA ==========
  Future<void> _ingestTestData() async {
    try {
      final now = DateTime.now();
      await _lifeLog.appendEntry({
        'type': 'test',
        'timestamp': now.toIso8601String(),
        'message': 'Test ingestion entry from simulator',
        'source': 'debug_mode',
        'date': now.millisecondsSinceEpoch,
      });
      print('Test data ingested');
    } catch (e) {
      print('Test data ingestion error: $e');
    }
  }

  Future<void> _ingestTestDataPastWeek(DateTime startTime, DateTime endTime) async {
    try {
      final now = DateTime.now();
      final daysSpan = endTime.difference(startTime).inDays;
      final sampleInterval = 3;
      
      int entryCount = 0;
      for (int day = 0; day < daysSpan; day += sampleInterval) {
        final entryTime = now.subtract(Duration(days: day));
        if (entryTime.isAfter(startTime) && entryTime.isBefore(endTime)) {
          await _lifeLog.appendEntry({
            'type': 'test',
            'timestamp': entryTime.toIso8601String(),
            'message': 'First-time install test entry - ${day} days ago',
            'source': 'first_time_setup',
            'date': entryTime.millisecondsSinceEpoch,
          });
          entryCount++;
        }
      }
      print('First-time test data ingested (past 6 months - $entryCount entries)');
    } catch (e) {
      print('First-time test data ingestion error: $e');
    }
  }
}


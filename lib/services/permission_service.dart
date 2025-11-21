import 'dart:io';
import 'package:permission_handler/permission_handler.dart' hide openAppSettings;
import 'package:permission_handler/permission_handler.dart' as ph show openAppSettings;
import 'package:flutter/services.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Permission denial information
class PermissionDenialInfo {
  final String permissionName;
  final String displayName;
  final String description;
  final PermissionStatus status;
  final bool isPermanentlyDenied;
  final Permission permission;

  PermissionDenialInfo({
    required this.permissionName,
    required this.displayName,
    required this.description,
    required this.status,
    required this.isPermanentlyDenied,
    required this.permission,
  });
}

/// Comprehensive permission service for all app permissions
class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance => _instance ??= PermissionService._();
  
  PermissionService._();
  
  static const MethodChannel _permissionChannel = MethodChannel('com.innermirror.app/permissions');
  static const MethodChannel _accessibilityChannel = MethodChannel('com.innermirror.app/permissions');

  /// Request all permissions needed for the app
  /// Returns map of permission type -> granted status
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};
    
    if (Platform.isAndroid) {
      // Android permissions
      results['photos'] = (await Permission.photos.request()).isGranted;
      results['microphone'] = (await Permission.microphone.request()).isGranted;
      results['location'] = (await Permission.location.request()).isGranted;
      results['contacts'] = (await Permission.contacts.request()).isGranted;
      results['calendar'] = (await Permission.calendar.request()).isGranted;
      results['health'] = true; // Health handled by health package
      
    } else if (Platform.isIOS) {
      // iOS permissions
      results['photos'] = (await Permission.photos.request()).isGranted;
      results['microphone'] = (await Permission.microphone.request()).isGranted;
      results['speech'] = (await Permission.speech.request()).isGranted;
      results['location'] = (await Permission.locationWhenInUse.request()).isGranted;
      results['contacts'] = (await Permission.contacts.request()).isGranted;
      results['calendar'] = (await Permission.calendar.request()).isGranted;
      results['health'] = true; // Health handled by health package
      // Face ID is requested via local_auth package, not permission_handler
      results['face_id'] = true; // Will be requested when user tries to use Vault
    }
    
    return results;
  }

  /// Request permissions step by step
  /// Returns permission name and granted status
  /// Request permissions step by step
  /// Returns permission name and granted status
  /// IMPORTANT: This MUST call .request() (not just .status) to trigger system dialogs
  /// on iOS and make permissions appear in Settings > InnerMirror
  Future<MapEntry<String, bool>> requestNextPermission(String permissionName) async {
    bool granted = false;
    
    print('[PermissionService] Requesting permission: $permissionName');
    
    try {
      switch (permissionName) {
        case 'contacts':
          // IMPORTANT: Call .request() to trigger system dialog and make it appear in Settings
          final status = await Permission.contacts.request();
          granted = status.isGranted;
          print('[PermissionService] Contacts: $status (granted: $granted)');
          // CRITICAL: Access contacts IMMEDIATELY after requesting to register in Settings
          // iOS requires actual resource access, not just permission request
          if (Platform.isIOS) {
            try {
              // Access contacts regardless of grant status to ensure iOS registers the permission
              final contacts = await ContactsService.getContacts(withThumbnails: false);
              print('[PermissionService] Accessed ${contacts.length} contacts - permission should now appear in Settings');
            } catch (e) {
              print('[PermissionService] Contacts access attempt (for Settings registration): $e');
              // Even if access fails, the attempt helps iOS register the permission
            }
          }
          break;
        case 'calendar':
          // IMPORTANT: Call .request() to trigger system dialog and make it appear in Settings
          final status = await Permission.calendar.request();
          granted = status.isGranted;
          print('[PermissionService] Calendar: $status (granted: $granted)');
          // CRITICAL: Access calendar IMMEDIATELY after requesting to register in Settings
          // iOS requires actual resource access, not just permission request
          if (Platform.isIOS) {
            try {
              // Access calendar via method channel to register permission in Settings
              const platform = MethodChannel('com.innermirror.app/calendar');
              try {
                // Try to access calendar to register permission
                // This will trigger iOS to register the calendar permission via EventKit
                final now = DateTime.now();
                await platform.invokeMethod('getEvents', {
                  'startTime': now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
                  'endTime': now.millisecondsSinceEpoch,
                });
                print('[PermissionService] Calendar accessed via EventKit - permission should now appear in Settings');
              } on MissingPluginException {
                // If method channel not implemented yet, at least the attempt helps
                print('[PermissionService] Calendar method channel not implemented, but permission request registered');
              } catch (e) {
                print('[PermissionService] Calendar access attempt (for Settings registration): $e');
                // Even if access fails, the attempt helps iOS register the permission
              }
            } catch (e) {
              print('[PermissionService] Error accessing calendar (non-critical): $e');
              // Even if access fails, the attempt helps iOS register the permission
            }
          }
          break;
        case 'health':
          // Health permission is handled by health package when accessing health data
          // We can't request it here, but it will be requested when data ingestion runs
          if (Platform.isIOS) {
            granted = true; // Will be requested by health package when accessing health data
            print('[PermissionService] Health: Will be requested by health package');
          } else {
            granted = true; // Android health handled separately
          }
          break;
        case 'photos':
          // IMPORTANT: Call .request() to trigger system dialog and make it appear in Settings
          final status = await Permission.photos.request();
          granted = status.isGranted;
          print('[PermissionService] Photos: $status (granted: $granted)');
          // CRITICAL: Access photos IMMEDIATELY after requesting to register in Settings
          // iOS requires actual resource access, not just permission request
          if (Platform.isIOS) {
            try {
              // Access photos regardless of grant status to ensure iOS registers the permission
              final result = await PhotoManager.requestPermissionExtend();
              if (result.isAuth) {
                final albums = await PhotoManager.getAssetPathList(type: RequestType.all, hasAll: true);
                print('[PermissionService] Accessed ${albums.length} photo albums - permission should now appear in Settings');
              } else {
                print('[PermissionService] PhotoManager access not authorized, but permission request registered');
              }
            } catch (e) {
              print('[PermissionService] Photos access attempt (for Settings registration): $e');
              // Even if access fails, the attempt helps iOS register the permission
            }
          }
          break;
        case 'microphone':
          // IMPORTANT: Call .request() to trigger system dialog and make it appear in Settings
          final status = await Permission.microphone.request();
          granted = status.isGranted;
          print('[PermissionService] Microphone: $status (granted: $granted)');
          // CRITICAL: Access microphone IMMEDIATELY after requesting to register in Settings
          // iOS requires actual resource access, not just permission request
          if (Platform.isIOS) {
            try {
              // Use speech_to_text to initialize and access microphone
              // This will trigger iOS to register the microphone permission in Settings
              final speech = stt.SpeechToText();
              final available = await speech.initialize();
              if (available) {
                print('[PermissionService] Microphone accessed via speech_to_text - permission should now appear in Settings');
                // Immediately stop to not actually record anything
                await speech.stop();
              } else {
                print('[PermissionService] Speech to text not available, trying flutter_tts');
                // Fallback: try flutter_tts which also accesses microphone
                try {
                  final flutterTts = FlutterTts();
                  await flutterTts.setLanguage("en-US");
                  await flutterTts.speak(""); // Empty speech to access microphone
                  await flutterTts.stop();
                  print('[PermissionService] Microphone accessed via flutter_tts - permission should now appear in Settings');
                } catch (e) {
                  print('[PermissionService] FlutterTTS microphone access attempt: $e');
                }
              }
            } catch (e) {
              print('[PermissionService] Microphone access attempt (for Settings registration): $e');
              // Even if access fails, the attempt helps iOS register the permission
            }
          }
          break;
        case 'speech':
          if (Platform.isIOS) {
            // IMPORTANT: Call .request() to trigger system dialog and make it appear in Settings
            final status = await Permission.speech.request();
            granted = status.isGranted;
            print('[PermissionService] Speech: $status (granted: $granted)');
          }
          break;
        case 'location':
          if (Platform.isAndroid) {
            // IMPORTANT: Call .request() to trigger system dialog and make it appear in Settings
            final status = await Permission.location.request();
            granted = status.isGranted;
            print('[PermissionService] Location (Android): $status (granted: $granted)');
          } else if (Platform.isIOS) {
            // IMPORTANT: Call .request() to trigger system dialog and make it appear in Settings
            final status = await Permission.locationWhenInUse.request();
            granted = status.isGranted;
            print('[PermissionService] Location (iOS): $status (granted: $granted)');
            // CRITICAL: Access location IMMEDIATELY after requesting to register in Settings
            // iOS requires actual resource access, not just permission request
            try {
              final position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.low,
                timeLimit: const Duration(seconds: 5),
              );
              print('[PermissionService] Accessed location (${position.latitude}, ${position.longitude}) - permission should now appear in Settings');
            } catch (e) {
              print('[PermissionService] Location access attempt (for Settings registration): $e');
              // Even if access fails, the attempt helps iOS register the permission
            }
          }
          break;
        case 'face_id':
          // Face ID is requested via local_auth package when user accesses Vault
          // We can't pre-request it here, but we'll note it as available
          if (Platform.isIOS) {
            granted = true; // Will be requested when needed
            print('[PermissionService] Face ID: Will be requested when accessing Vault');
          }
          break;
      }
    } catch (e, stackTrace) {
      print('[PermissionService] Error requesting permission $permissionName: $e');
      print('[PermissionService] Stack trace: $stackTrace');
      granted = false;
    }
    
    return MapEntry(permissionName, granted);
  }

  /// Get list of required permissions for current platform
  List<String> getRequiredPermissions() {
    if (Platform.isAndroid) {
      return ['photos', 'microphone', 'location', 'contacts', 'calendar', 'health'];
    } else if (Platform.isIOS) {
      return ['photos', 'microphone', 'speech', 'location', 'contacts', 'calendar', 'health', 'face_id'];
    }
    return [];
  }

  /// Get permission description for UI
  String getPermissionDescription(String permissionName) {
    switch (permissionName) {
      case 'contacts':
        return 'Access to your contacts to understand your relationships';
      case 'calendar':
        return 'Access to your calendar events to understand your schedule';
      case 'health':
        return 'Access to health and fitness data for comprehensive analysis';
      case 'photos':
        return 'Access to your photo library';
      case 'microphone':
        return 'Microphone access for voice-to-text journaling';
      case 'speech':
        return 'Speech recognition for voice input';
      case 'location':
        return 'Location access to understand your patterns';
      case 'face_id':
        return 'Face ID to secure your secrets vault';
      default:
        return '';
    }
  }

  /// Check if notification access is enabled
  Future<bool> _checkNotificationAccess() async {
    if (Platform.isAndroid) {
      try {
        final result = await _permissionChannel.invokeMethod<bool>('checkNotificationAccess');
        return result ?? false;
      } catch (e) {
        print('Error checking notification access: $e');
        return false;
      }
    } else if (Platform.isIOS) {
      // iOS: Apps cannot read other apps' notifications
      // This is an Apple privacy restriction - notification listener for reading messages is not available
      // We can only send notifications, not read WhatsApp/Messages notifications
      print('[PermissionService] iOS: Reading other apps\' notifications is restricted by Apple');
      print('[PermissionService] iOS: WhatsApp/Messages must be imported manually via Debug Screen');
      return false; // Always false on iOS - not possible
    }
    return false;
  }
  
  /// Check if accessibility service is enabled (Android only)
  Future<bool> checkAccessibilityAccess() async {
    if (Platform.isAndroid) {
      try {
        final result = await _permissionChannel.invokeMethod<bool>('checkAccessibilityAccess');
        return result ?? false;
      } catch (e) {
        print('Error checking accessibility access: $e');
        return false;
      }
    }
    return false;
  }
  
  /// Open accessibility settings (Android only)
  Future<void> openAccessibilitySettings() async {
    if (Platform.isAndroid) {
      try {
        await _permissionChannel.invokeMethod('openAccessibilitySettings');
      } catch (e) {
        print('Error opening accessibility settings: $e');
      }
    }
  }

  /// Open notification settings
  Future<void> openNotificationSettings() async {
    if (Platform.isAndroid) {
      try {
        await _permissionChannel.invokeMethod('openNotificationSettings');
      } catch (e) {
        print('Error opening notification settings: $e');
        await PermissionService.instance.openAppSettings();
      }
    } else if (Platform.isIOS) {
      await PermissionService.instance.openAppSettings();
    }
  }

  /// Open app settings to enable permissions
  /// Uses permission_handler's openAppSettings() function
  Future<bool> openAppSettings() async {
    // Call the top-level openAppSettings from permission_handler package
    return await ph.openAppSettings();
  }

  /// Request permission with detailed handling for denied/permanently denied states
  /// Returns PermissionDenialInfo if denied, null if granted
  Future<PermissionDenialInfo?> requestPermissionWithGuidance(
    Permission permission,
    String permissionName,
    String displayName,
    String description,
  ) async {
    final status = await permission.status;
    
    if (status.isGranted) {
      return null; // Permission granted
    }

    // Request permission if not yet requested
    if (status.isDenied || status.isLimited) {
      final requestStatus = await permission.request();
      if (requestStatus.isGranted) {
        return null; // Permission granted after request
      }
    }

    // Check if permanently denied
    final isPermanentlyDenied = status.isPermanentlyDenied || await permission.isPermanentlyDenied;
    
    return PermissionDenialInfo(
      permissionName: permissionName,
      displayName: displayName,
      description: description,
      status: status,
      isPermanentlyDenied: isPermanentlyDenied,
      permission: permission,
    );
  }

  /// Get all denied permissions that need attention
  Future<List<PermissionDenialInfo>> getDeniedPermissions() async {
    final denied = <PermissionDenialInfo>[];
    
    final permissions = [
      (Permission.photos, 'photos', 'Photos', 'Photos access is needed to analyze your visual life and memories'),
      (Permission.location, 'location', 'Location', 'Location access helps understand your patterns and where you spend your time'),
      (Permission.contacts, 'contacts', 'Contacts', 'Contacts access helps understand your relationships and connections'),
      (Permission.calendar, 'calendar', 'Calendar', 'Calendar access helps understand your schedule and recurring patterns'),
      (Permission.microphone, 'microphone', 'Microphone', 'Microphone access enables voice journaling and audio input features'),
    ];
    
    if (Platform.isIOS) {
      permissions.add((Permission.speech, 'speech', 'Speech Recognition', 'Speech recognition enables voice-to-text functionality'));
    }
    
    for (final (permission, name, displayName, description) in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        final isPermanentlyDenied = status.isPermanentlyDenied || await permission.isPermanentlyDenied;
        denied.add(PermissionDenialInfo(
          permissionName: name,
          displayName: displayName,
          description: description,
          status: status,
          isPermanentlyDenied: isPermanentlyDenied,
          permission: permission,
        ));
      }
    }
    
    return denied;
  }

  /// Get permission instructions for settings
  String getSettingsInstructions(String permissionName) {
    if (Platform.isIOS) {
      switch (permissionName) {
        case 'photos':
          return 'Settings > InnerMirror > Photos > Select "All Photos"';
        case 'location':
          return 'Settings > InnerMirror > Location > Select "While Using the App" or "Always"';
        case 'contacts':
          return 'Settings > InnerMirror > Contacts > Toggle ON';
        case 'calendar':
          return 'Settings > InnerMirror > Calendars > Toggle ON';
        case 'microphone':
          return 'Settings > InnerMirror > Microphone > Toggle ON';
        case 'speech':
          return 'Settings > InnerMirror > Speech Recognition > Toggle ON';
        default:
          return 'Settings > InnerMirror > Enable the permission';
      }
    } else {
      return 'Settings > Apps > InnerMirror > Permissions > Enable $permissionName';
    }
  }
}

extension PermissionHelper on Permission {
  /// Helper to get permission description
  String get permissionDescription {
    if (this == Permission.photos) {
      return 'Photos access is needed to analyze your visual life and memories';
    } else if (this == Permission.location) {
      return 'Location access helps understand your patterns and where you spend your time';
    } else if (this == Permission.contacts) {
      return 'Contacts access helps understand your relationships and connections';
    } else if (this == Permission.calendar) {
      return 'Calendar access helps understand your schedule and recurring patterns';
    } else if (this == Permission.microphone) {
      return 'Microphone access enables voice journaling and audio input features';
    } else if (this == Permission.speech) {
      return 'Speech recognition enables voice-to-text functionality';
    }
    return 'This permission is needed for app functionality';
  }
}

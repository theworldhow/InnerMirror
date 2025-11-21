import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Service to handle permission requests for Messages and WhatsApp
class MessagePermissionService {
  static MessagePermissionService? _instance;
  static MessagePermissionService get instance => _instance ??= MessagePermissionService._();
  
  MessagePermissionService._();
  
  static const MethodChannel _permissionChannel = MethodChannel('com.innermirror.app/permissions');

  /// Request message-related permissions only (SMS, Phone, Notification Access)
  /// Returns map of permission type -> granted status
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};
    
    if (Platform.isAndroid) {
      // Android: Request SMS and Phone permissions (for SMS access)
      final smsPermission = await Permission.sms.request();
      results['sms'] = smsPermission.isGranted;
      
      final phonePermission = await Permission.phone.request();
      results['phone'] = phonePermission.isGranted;
      
      // Check notification access for WhatsApp (requires user to enable in system settings)
      // This cannot be requested programmatically - user must enable manually
      final notificationAccess = await _checkNotificationAccess();
      results['notification_access'] = notificationAccess;
      
      print('[MessagePermissionService] Android permissions - SMS: ${results['sms']}, Phone: ${results['phone']}, Notification Access: ${results['notification_access']}');
    } else if (Platform.isIOS) {
      // iOS: Request SMS permission (attempting full access)
      final smsPermission = await Permission.sms.request();
      results['sms'] = smsPermission.isGranted;
      
      // Check notification access for WhatsApp and Messages (iOS)
      // This requires user to enable in Settings > Notifications
      final notificationAccess = await _checkNotificationAccess();
      results['notification_access'] = notificationAccess;
      
      print('[MessagePermissionService] iOS SMS permission: ${results['sms']}');
      print('[MessagePermissionService] iOS Notification access: ${results['notification_access']}');
    }
    
    return results;
  }

  /// Check if notification access is enabled (Android & iOS)
  Future<bool> _checkNotificationAccess() async {
    if (Platform.isAndroid) {
    
    try {
      // Check via method channel if notification listener service is enabled
      final result = await _permissionChannel.invokeMethod<bool>('checkNotificationAccess');
      return result ?? false;
    } catch (e) {
      print('Error checking notification access: $e');
      return false;
    }
    } else if (Platform.isIOS) {
      // iOS: Check if notification listener is enabled
      // Note: iOS notification listener setup may differ from Android
      try {
        // For iOS, we can check notification authorization status
        // This may require additional iOS-specific implementation
        print('[MessagePermissionService] iOS notification access check - may require user setup');
        return false; // Default to false, user must enable manually
      } catch (e) {
        print('Error checking iOS notification access: $e');
        return false;
      }
    }
    return false;
  }

  /// Get permission status summary for display
  Future<Map<String, String>> getPermissionStatus() async {
    final status = <String, String>{};
    
    if (Platform.isAndroid) {
      final smsStatus = await Permission.sms.status;
      status['sms'] = smsStatus.toString();
      
      final phoneStatus = await Permission.phone.status;
      status['phone'] = phoneStatus.toString();
      
      status['notification_access'] = 'requires_manual_setup';
    } else if (Platform.isIOS) {
      final smsStatus = await Permission.sms.status;
      status['sms'] = smsStatus.toString();
      status['messages_full_access'] = 'not_available';
    }
    
    return status;
  }

  /// Open system settings for notification access (Android)
  Future<void> openNotificationSettings() async {
    if (!Platform.isAndroid) return;
    
    try {
      // Open Android Notification Listener settings directly
      await _permissionChannel.invokeMethod('openNotificationSettings');
    } catch (e) {
      print('Error opening notification settings: $e');
      // Fallback to general app settings
      await openAppSettings();
    }
  }
}


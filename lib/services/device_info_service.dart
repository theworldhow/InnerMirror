import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<int> getTotalMemoryGB() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Android doesn't directly expose total RAM, but we can estimate
        // For now, return a conservative estimate or use system properties
        // This is a simplified approach - in production you'd use platform channels
        return 4; // Default conservative estimate
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // iOS devices have known RAM amounts
        // iPhone 14 Pro and newer typically have 6GB+
        // iPhone 13 and older typically have 4-6GB
        final model = iosInfo.model.toLowerCase();
        if (model.contains('iphone15') || 
            model.contains('iphone16') || 
            model.contains('iphone14pro') ||
            model.contains('iphone13pro')) {
          return 6;
        }
        return 4; // Conservative default
      }
    } catch (e) {
      // If we can't determine, be conservative
    }
    return 4; // Default to 4GB (will use 3B model)
  }

  Future<bool> shouldUse8BModel() async {
    final memoryGB = await getTotalMemoryGB();
    return memoryGB >= 8;
  }
}


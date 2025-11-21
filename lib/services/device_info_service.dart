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
    // Default to smaller models - use 8B only for high-end devices
    final memoryGB = await getTotalMemoryGB();
    return memoryGB >= 8;
  }

  // Get recommended model size based on device
  // Default to 3B model for better performance
  Future<String> getRecommendedModelSize({bool prefer1B = false}) async {
    // Default to 3B for better quality
    final memoryGB = await getTotalMemoryGB();
    if (memoryGB >= 8) {
      return '8B'; // Best quality for high-end devices
    } else if (memoryGB >= 4 || !prefer1B) {
      return '3B'; // Balanced - default for better performance
    } else {
      return '1B'; // Smallest, for devices with limited RAM
    }
  }
  
  // Check if device can handle larger model
  Future<bool> canUse3BModel() async {
    final memoryGB = await getTotalMemoryGB();
    return memoryGB >= 4;
  }
  
  Future<bool> canUse8BModel() async {
    final memoryGB = await getTotalMemoryGB();
    return memoryGB >= 8;
  }
}


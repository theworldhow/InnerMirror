import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/soul_model_service.dart';
import '../services/device_info_service.dart';
import '../services/mirror_generation_service.dart';

final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService();
});

// ModelDownloadService removed - no longer using LLM

final soulModelServiceProvider = Provider<SoulModelService>((ref) {
  final service = SoulModelService.instance;
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final modelStateProvider = StateProvider<ModelState>((ref) {
  return ModelState.notInitialized;
});

final modelDownloadProgressProvider = StateProvider<double>((ref) {
  return 0.0;
});

final shouldUse8BModelProvider = FutureProvider<bool>((ref) async {
  final deviceInfo = ref.watch(deviceInfoServiceProvider);
  return await deviceInfo.shouldUse8BModel();
});

final modelInitializedProvider = FutureProvider<bool>((ref) async {
  // Always ready now - using NLP instead of LLM
  // No model download or initialization needed
  final modelService = ref.watch(soulModelServiceProvider);
  
  // Initialize (stub - always succeeds)
  if (modelService.state == ModelState.notInitialized) {
    await modelService.initialize();
    ref.read(modelStateProvider.notifier).state = modelService.state;
  }

  return modelService.state == ModelState.ready;
});

// Provider to notify mirror cards when mirrors are regenerated
// The callback is set up in main.dart
final mirrorRegeneratedProvider = StateProvider<int>((ref) => 0);


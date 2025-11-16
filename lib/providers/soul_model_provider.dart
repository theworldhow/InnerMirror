import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/soul_model_service.dart';
import '../services/model_download_service.dart';
import '../services/device_info_service.dart';

final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService();
});

final modelDownloadServiceProvider = Provider<ModelDownloadService>((ref) {
  return ModelDownloadService();
});

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
  final use8B = await ref.watch(shouldUse8BModelProvider.future);
  final downloadService = ref.watch(modelDownloadServiceProvider);
  final modelService = ref.watch(soulModelServiceProvider);
  
  final exists = await downloadService.modelExists(use8B: use8B);
  
  if (!exists) {
    return false;
  }

  if (modelService.state == ModelState.notInitialized) {
    await modelService.initialize(use8B: use8B);
    ref.read(modelStateProvider.notifier).state = modelService.state;
  }

  return modelService.state == ModelState.ready;
});


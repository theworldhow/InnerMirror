import 'dart:io';
import 'package:path_provider/path_provider.dart';
// import 'package:mllama_flutter/mllama_flutter.dart';  // Not available - using stub
import 'mllama_stub.dart' as mllama;
import 'model_download_service.dart';

enum ModelState {
  notInitialized,
  downloading,
  loading,
  ready,
  sleeping,
  generating,
  error,
}

class SoulModelService {
  static SoulModelService? _instance;
  static SoulModelService get instance => _instance ??= SoulModelService._();
  
  SoulModelService._();

  ModelState _state = ModelState.notInitialized;
  String? _errorMessage;
  bool _use8B = true;
  mllama.MLLamaContext? _llamaContext;
  String? _modelPath;

  ModelState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get use8B => _use8B;
  bool get isReady => _state == ModelState.ready;

  Future<void> initialize({required bool use8B}) async {
    _use8B = use8B;
    _state = ModelState.loading;
    _errorMessage = null;

    try {
      final downloadService = ModelDownloadService();
      final modelFile = await downloadService.getModelFile(use8B: use8B);
      _modelPath = modelFile.path;

      if (!await modelFile.exists()) {
        _state = ModelState.error;
        _errorMessage = 'Model file not found at $_modelPath';
        return;
      }

      // Initialize MLLamaContext with the model
      _llamaContext = mllama.MLLamaContext(
        modelPath: _modelPath!,
      );

      await _llamaContext!.load();
      
      _state = ModelState.ready;
    } catch (e) {
      _state = ModelState.error;
      _errorMessage = e.toString();
      _llamaContext = null;
    }
  }

  Future<String> generateResponse(String prompt) async {
    if (_state == ModelState.sleeping) {
      await wake();
    }

    if (_state != ModelState.ready && _state != ModelState.generating) {
      throw Exception('Model is not ready. State: $_state');
    }

    if (_llamaContext == null) {
      throw Exception('Model context not initialized');
    }

    _state = ModelState.generating;

    try {
      // Configure generation parameters
      final params = mllama.MLLamaGenerateParams(
        prompt: prompt,
        temperature: 0.7,
        topP: 0.95,
        maxTokens: 300,
      );

      // Generate response
      final response = await _llamaContext!.generate(params);
      
      _state = ModelState.ready;
      return response;
    } catch (e) {
      _state = ModelState.error;
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<void> wake() async {
    if (_state == ModelState.sleeping) {
      // Reinitialize if needed
      if (_llamaContext == null && _modelPath != null) {
        await initialize(use8B: _use8B);
      } else {
        _state = ModelState.ready;
      }
    }
  }

  void sleep() {
    if (_state == ModelState.ready) {
      _state = ModelState.sleeping;
      // Keep context loaded but mark as sleeping
    }
  }

  void dispose() {
    _llamaContext?.dispose();
    _llamaContext = null;
    _state = ModelState.notInitialized;
  }
}

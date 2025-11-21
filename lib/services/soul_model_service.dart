// Stub service - no longer using LLM
// Kept for compatibility with existing code that checks model state
// The app now uses SimpleNLPService for generating responses

enum ModelState {
  notInitialized,
  ready,
  error,
}

class SoulModelService {
  static SoulModelService? _instance;
  static SoulModelService get instance => _instance ??= SoulModelService._();
  
  SoulModelService._();
  
  ModelState get state => ModelState.ready; // Always ready - using NLP now
  bool get isReady => true; // Always ready - using NLP now
  String? get errorMessage => null; // No errors - using NLP now
  
  // No-op methods for compatibility
  Future<void> initialize({bool use8B = false, bool use3B = true, bool use1B = false}) async {
    // No-op - using SimpleNLPService instead
  }
  
  Future<String> generateResponse(String prompt) async {
    throw UnimplementedError('Use SimpleNLPService.generateResponse() instead');
  }
  
  void dispose() {
    // No-op
  }
}


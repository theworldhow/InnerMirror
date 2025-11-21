import 'soul_model_service.dart';

class RegretSimulatorService {
  static RegretSimulatorService? _instance;
  static RegretSimulatorService get instance => _instance ??= RegretSimulatorService._();
  
  RegretSimulatorService._();
  
  final SoulModelService _soulModel = SoulModelService.instance;

  Future<RegretAnalysis> analyzeText(String text) async {
    // Simple NLP-based regret analysis - no LLM needed
    if (text.split(RegExp(r'\s+')).length <= 2) {
      return RegretAnalysis(
        regretChance: 0,
        reason: 'Text too short',
        suggestedEdit: null,
      );
    }
    
    // Simple pattern-based regret analysis
    final regretIndicators = ['hate', 'stupid', 'idiot', 'never', 'always', 'you always', 'you never'];
    final apologyIndicators = ['sorry', 'apologize', 'regret', 'mistake'];
    
    int regretScore = 0;
    for (final indicator in regretIndicators) {
      if (text.toLowerCase().contains(indicator)) {
        regretScore += 15;
      }
    }
    
    // Check for emotional intensity
    final emotionalWords = text.split(RegExp(r'\s+')).where((word) => 
      word.length > 5 && RegExp(r'[!?]{2,}').hasMatch(word)
    ).length;
    regretScore += emotionalWords * 10;
    
    final regretChance = regretScore.clamp(0, 100);
    String reason = regretChance > 50 
      ? 'High emotional intensity detected'
      : 'Message seems reasonable';
    
    return RegretAnalysis(
      regretChance: regretChance,
      reason: reason,
      suggestedEdit: regretChance > 70 ? 'Consider waiting before sending' : null,
    );
  }

  // _parseResponse removed - using direct NLP analysis now
}

class RegretAnalysis {
  final int regretChance;
  final String reason;
  final String? suggestedEdit;

  RegretAnalysis({
    required this.regretChance,
    required this.reason,
    this.suggestedEdit,
  });
}


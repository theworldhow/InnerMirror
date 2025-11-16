import 'soul_model_service.dart';

class RegretSimulatorService {
  static RegretSimulatorService? _instance;
  static RegretSimulatorService get instance => _instance ??= RegretSimulatorService._();
  
  RegretSimulatorService._();
  
  final SoulModelService _soulModel = SoulModelService.instance;

  Future<RegretAnalysis> analyzeText(String text) async {
    if (_soulModel.state != ModelState.ready) {
      return RegretAnalysis(
        regretChance: 0,
        reason: 'Model not ready',
        suggestedEdit: null,
      );
    }

    if (text.split(RegExp(r'\s+')).length <= 2) {
      return RegretAnalysis(
        regretChance: 0,
        reason: 'Text too short',
        suggestedEdit: null,
      );
    }

    final prompt = """Analyze this message I'm about to send. Will I regret it in 72 hours?

Message: "$text"

Output EXACTLY in this format:
REGRET_CHANCE: [0-100]%
REASON: [one sentence explaining why]
SUGGESTED_EDIT: [improved version or "send as is"]

Be brutal. Be honest. Consider tone, timing, emotional state, relationship dynamics.""";

    try {
      final response = await _soulModel.generateResponse(prompt);
      return _parseResponse(response, text);
    } catch (e) {
      return RegretAnalysis(
        regretChance: 50,
        reason: 'Analysis failed: $e',
        suggestedEdit: null,
      );
    }
  }

  RegretAnalysis _parseResponse(String response, String originalText) {
    int regretChance = 50;
    String reason = 'Unable to analyze';
    String? suggestedEdit;

    try {
      final lines = response.split('\n');
      for (final line in lines) {
        if (line.startsWith('REGRET_CHANCE:')) {
          final match = RegExp(r'(\d+)%').firstMatch(line);
          if (match != null) {
            regretChance = int.parse(match.group(1)!);
          }
        } else if (line.startsWith('REASON:')) {
          reason = line.substring(7).trim();
        } else if (line.startsWith('SUGGESTED_EDIT:')) {
          final edit = line.substring(15).trim();
          if (edit.toLowerCase() != 'send as is') {
            suggestedEdit = edit;
          }
        }
      }
    } catch (e) {
      // Fallback parsing
    }

    return RegretAnalysis(
      regretChance: regretChance,
      reason: reason,
      suggestedEdit: suggestedEdit,
    );
  }
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


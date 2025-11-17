import 'package:flutter/foundation.dart';

/// Screenshot mode for App Store screenshots
/// Shows sample content with appropriate blurring
class ScreenshotMode {
  static bool _enabled = false;
  
  static bool get enabled => _enabled || kDebugMode && const bool.fromEnvironment('SCREENSHOT_MODE', defaultValue: false);
  
  static void enable() {
    _enabled = true;
  }
  
  static void disable() {
    _enabled = false;
  }
  
  /// Sample content for each mirror type (blurred for screenshots)
  static const Map<String, String> sampleContent = {
    'truth': '12 times you said you were fine when you weren\'t.\n\nLast one: "I\'m okay, just tired" to Sarah on March 15, 2:30 PM.\n\nHere\'s the pattern: You retreat into silence when overwhelmed, hoping someone will notice without you having to ask.',
    'strength': 'You win 87% of the time when you set clear boundaries first.\n\nDo that more.',
    'shadow': 'You deflect with humor when you feel vulnerable.\n\nLast time: Alex on March 12.\n\nFix it: Pause. Breathe. Say "I need a moment."',
    'growth': 'You\'re 34% better at saying no than last year.\n\nNext level: Stop explaining your boundaries.',
    'legacy': 'In 40 years, this week will be remembered as the moment you stopped waiting for permission to be yourself.',
  };
  
  /// Blur text for screenshot mode - subtle blur that maintains structure
  static String blurText(String text, {double blurAmount = 0.5}) {
    if (!enabled) return text;
    
    // Subtle blur: replace specific names, dates, and numbers while keeping structure
    var blurred = text;
    
    // Replace names (capitalized words that might be names)
    blurred = blurred.replaceAllMapped(RegExp(r'\b[A-Z][a-z]+\b'), (match) {
      final word = match.group(0)!;
      // Keep common words, blur potential names
      if (['You', 'The', 'This', 'That', 'When', 'What', 'Where', 'How', 'Why', 'Last', 'Next', 'Here', 'There'].contains(word)) {
        return word;
      }
      // Blur names with similar length
      return '•' * word.length;
    });
    
    // Replace dates and times
    blurred = blurred.replaceAllMapped(RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}'), (match) => '••/••/••');
    blurred = blurred.replaceAllMapped(RegExp(r'\d{1,2}:\d{2}\s*(AM|PM)?', caseSensitive: false), (match) => '••:••');
    blurred = blurred.replaceAllMapped(RegExp(r'\b(March|April|May|June|July|August|September|October|November|December|January|February)\s+\d{1,2}', caseSensitive: false), (match) => '••••• ••');
    
    // Replace specific numbers (percentages, counts) with blurred versions
    blurred = blurred.replaceAllMapped(RegExp(r'\b\d+%'), (match) => '••%');
    blurred = blurred.replaceAllMapped(RegExp(r'\b\d+\s+times'), (match) => '•• times');
    blurred = blurred.replaceAllMapped(RegExp(r'\b\d+'), (match) {
      final num = match.group(0)!;
      return '•' * num.length;
    });
    
    // Replace quoted strings (personal messages)
    blurred = blurred.replaceAllMapped(RegExp(r'"[^"]*"'), (match) => '"••••••••••"');
    
    return blurred;
  }
}


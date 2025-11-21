import 'dart:convert';
import 'dart:math';

/// Simple NLP-based service for generating mirror responses
/// Uses pattern matching, keyword extraction, and rule-based generation
/// No LLM required - works entirely with ingested data
class SimpleNLPService {
  static SimpleNLPService? _instance;
  static SimpleNLPService get instance => _instance ??= SimpleNLPService._();
  
  SimpleNLPService._();
  
  final Random _random = Random();

  /// Generate a response based on analyzed data and a template
  Future<String> generateResponse({
    required String prompt,
    required String lifeLogContent,
  }) async {
    // Parse the prompt to understand what kind of mirror we're generating
    final lowerPrompt = prompt.toLowerCase();
    
    if (lowerPrompt.contains('truth') || lowerPrompt.contains('fine when you weren\'t') || lowerPrompt.contains('truth mirror')) {
      return _generateTruthResponse(lifeLogContent);
    } else if (lowerPrompt.contains('strength') || lowerPrompt.contains('superpower') || lowerPrompt.contains('strength mirror')) {
      return _generateStrengthResponse(lifeLogContent);
    } else if (lowerPrompt.contains('shadow') || lowerPrompt.contains('avoidance') || lowerPrompt.contains('shadow mirror')) {
      return _generateShadowResponse(lifeLogContent);
    } else if (lowerPrompt.contains('growth') || 
               lowerPrompt.contains('better than last year') || 
               lowerPrompt.contains('growth mirror') || 
               lowerPrompt.contains('better at') ||
               lowerPrompt.contains('compare this year') ||
               (lowerPrompt.contains('compare') && lowerPrompt.contains('year'))) {
      return _generateGrowthResponse(lifeLogContent);
    } else if (lowerPrompt.contains('legacy') || lowerPrompt.contains('remembered') || lowerPrompt.contains('legacy mirror') || lowerPrompt.contains('2065')) {
      return _generateLegacyResponse(lifeLogContent);
    }
    
    // Default response - should rarely be reached
    return _generateDefaultResponse(lifeLogContent);
  }

  /// Generate Truth Mirror response - Dynamic and data-driven
  /// Analyzes ALL data sources: photos, health, location, calendar, contacts, reminders, notes, audio, app usage, and communications
  String _generateTruthResponse(String lifeLogContent) {
    final entries = _parseLifeLog(lifeLogContent);
    final now = DateTime.now();
    
    // Filter entries with valid dates
    final validEntries = entries.where((e) {
      if (e['date'] == null) return false;
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.year > 2000;
    }).toList();
    
    // Categorize entries by type to analyze all data sources
    final photoEntries = validEntries.where((e) => e['type'] == 'photo').toList();
    final healthEntries = validEntries.where((e) => e['type'] != null && (e['type'] as String).startsWith('health_')).toList();
    final locationEntries = validEntries.where((e) => e['type'] == 'location').toList();
    final calendarEntries = validEntries.where((e) => e['type'] == 'calendar_event').toList();
    final contactEntries = validEntries.where((e) => e['type'] == 'contact').toList();
    final reminderEntries = validEntries.where((e) => e['type'] == 'reminder').toList();
    final noteEntries = validEntries.where((e) => e['type'] == 'note').toList();
    final audioEntries = validEntries.where((e) => e['type'] == 'audio').toList();
    final appUsageEntries = validEntries.where((e) => e['type'] == 'app_usage').toList();
    
    // Get text/communication entries
    final textEntries = validEntries.where((e) {
      final hasText = e['body'] != null || e['text'] != null || e['message'] != null;
      final isCommunication = e['type'] == 'journal';
      return hasText || isCommunication;
    }).toList();
    
    // Analyze this week vs last week across all data types
    final thisWeekEntries = validEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    final lastWeekEntries = validEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 14))) &&
             date.isBefore(now.subtract(const Duration(days: 7)));
    }).toList();
    
    // If no entries at all, show initial message
    if (validEntries.isEmpty) {
      return """THE TRUTH MIRROR

No data available yet.

Your truth is waiting to be discovered through the moments you capture.

To begin:
- Grant permissions for Photos, Health, Location, Calendar, Contacts, Reminders, Notes, and Microphone
- Use the journal feature to add entries manually
- Use the Debug Screen (shake phone) to force data ingestion

Once data starts flowing, the Truth Mirror will reveal authentic patterns about how you show up in the world.

The truth about you is already there. Start tracking to see it reflected back.""";
    }
    
    // Analyze patterns across all data sources to reveal truth
    // Look for discrepancies between what you do and what you say
    
    // Pattern 1: Analyze location patterns (where you actually are vs where you say you'll be)
    final locationPattern = _analyzeLocationPattern(locationEntries, calendarEntries, thisWeekEntries);
    
    // Pattern 2: Analyze activity patterns (what you actually do vs what you plan)
    final activityPattern = _analyzeActivityPattern(healthEntries, calendarEntries, appUsageEntries, thisWeekEntries);
    
    // Pattern 3: Analyze social patterns (who you interact with vs who you say you interact with)
    final socialPattern = _analyzeSocialPattern(contactEntries, calendarEntries, textEntries, thisWeekEntries);
    
    // Pattern 4: Analyze time patterns (how you actually spend time vs how you plan to)
    final timePattern = _analyzeTimePattern(calendarEntries, appUsageEntries, locationEntries, thisWeekEntries);
    
    // Pattern 5: Analyze documentation patterns (what you capture vs what you experience)
    final documentationPattern = _analyzeDocumentationPattern(photoEntries, locationEntries, textEntries, thisWeekEntries);
    
    // Generate response based on detected patterns across all data sources
    if (locationPattern != null) {
      return locationPattern;
    } else if (activityPattern != null) {
      return activityPattern;
    } else if (socialPattern != null) {
      return socialPattern;
    } else if (timePattern != null) {
      return timePattern;
    } else if (documentationPattern != null) {
      return documentationPattern;
    }
    
    // Fallback: Analyze text communications for "I'm fine" patterns (if available)
    
    // Count "I'm fine" variations with context
    final finePatterns = ['fine', 'okay', 'ok', 'alright', 'good', 'doing well', 'all good', "i'm fine", "im fine", "doing great", "can't complain"];
    final fineEntries = <Map<String, dynamic>>[];
    final fineToPersons = <String, List<String>>{};
    
    for (final entry in textEntries.reversed.take(50)) { // Analyze recent entries
      final text = ((entry['body'] as String?) ?? (entry['text'] as String?) ?? (entry['message'] as String?))?.toLowerCase() ?? '';
      final originalText = (entry['body'] as String?) ?? (entry['text'] as String?) ?? (entry['message'] as String?) ?? '';
      
      for (final pattern in finePatterns) {
        if (text.contains(pattern)) {
          fineEntries.add(entry);
          final from = entry['from'] ?? 'someone';
          fineToPersons.putIfAbsent(from, () => []).add(originalText.length > 60 ? originalText.substring(0, 60) : originalText);
          break;
        }
      }
    }
    
    final thisWeekFine = fineEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).length;
    
    final lastWeekFine = fineEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 14))) &&
             date.isBefore(now.subtract(const Duration(days: 7)));
    }).length;
    
    // Handle case when no fine patterns found but we have text entries
    if (thisWeekFine == 0 && textEntries.isNotEmpty) {
      // Sort entries by date to get the most recent
      final sortedEntries = List<Map<String, dynamic>>.from(textEntries);
      sortedEntries.sort((a, b) {
        final dateA = DateTime.fromMillisecondsSinceEpoch(a['date'] as int? ?? 0);
        final dateB = DateTime.fromMillisecondsSinceEpoch(b['date'] as int? ?? 0);
        return dateB.compareTo(dateA); // Descending - newest first
      });
      
      final lastEntry = sortedEntries.isNotEmpty ? sortedEntries.first : textEntries.first;
      final lastText = (lastEntry['body'] ?? lastEntry['text'] ?? lastEntry['message'] ?? '').toString();
      final lastDate = lastEntry['date'] != null && lastEntry['date'] is int
          ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastEntry['date'] as int))
          : 'recently';
      final lastFrom = lastEntry['from'] ?? 'you';
      
      final templates = [
        """THE TRUTH MIRROR

This week reveals something important about you.

You chose honesty over comfort. This is unusual. Most people hide behind comfortable phrases. You don't.

Look at what you actually said:
"${lastText.length > 90 ? lastText.substring(0, 90) + '...' : lastText}"

That was on $lastDate to ${lastFrom}. 

The insight:
When you speak, you speak truth. Even when it's uncomfortable. Even when it's hard.

Why this matters:
Authentic communication creates authentic relationships. You're building something real here.

Keep this. Protect this. It's rare.""",
        
        """THE TRUTH MIRROR

A clear pattern emerged this week:

You showed up honestly. No masks detected.

Your last message on ${lastDate} to ${lastFrom}:
"${lastText.length > 80 ? lastText.substring(0, 80) + '...' : lastText}"

The truth about you:
You're not wearing a mask. You're not hiding. You're showing up as you are.

Most people spend their lives behind walls. You're choosing vulnerability instead.

What this means:
Real connection requires real honesty. You're already there.

Keep choosing truth. It's your strength.""",
      ];
      
      return templates[_random.nextInt(templates.length)];
    }
    
    // Dynamic response when fine patterns are detected
    final mostFrequentPerson = fineToPersons.entries.isEmpty 
        ? null 
        : fineToPersons.entries.reduce((a, b) => a.value.length > b.value.length ? a : b);
    
    // Remove percentage calculation - we don't use it anymore
    
    // Determine trend qualitatively without numbers
    final trendText = lastWeekFine > 0
        ? (thisWeekFine > lastWeekFine + (lastWeekFine * 0.2).round())
            ? 'The pattern is intensifying this week.'
            : (thisWeekFine < lastWeekFine - (lastWeekFine * 0.2).round())
                ? 'You are becoming more honest this week.'
                : 'Similar to last week. The pattern persists.'
        : 'This is the first time we are tracking this pattern.';
    
    final recentFine = fineEntries.isNotEmpty 
        ? fineEntries.first 
        : null;
    final recentQuoteText = recentFine != null
        ? ((recentFine['body'] ?? recentFine['text'] ?? recentFine['message']) as String? ?? '')
        : '';
    final recentQuote = recentQuoteText.length > 100
        ? '${recentQuoteText.substring(0, 100)}...'
        : recentQuoteText;
    final recentDate = recentFine != null && recentFine['date'] != null
        ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(recentFine['date'] as int))
        : 'recently';
    final recentFrom = recentFine?['from'] ?? 'someone';
    
    final templates = [
      """THE TRUTH MIRROR

This week you said you were fine when you weren't.

The pattern is clear. You're protecting yourself. Or protecting them. But every "I'm fine" when you're not fine creates distance.

The most recent example:
$recentDate
To $recentFrom: "$recentQuote"

${mostFrequentPerson != null ? 'You do this often with ${mostFrequentPerson.key}. That relationship might need more honesty.\n\n' : ''}What's happening:
The more you hide, the more alone you become. The more alone you become, the more you hide.

Break the cycle:
Next time ${recentFrom} asks how you are, try this: "Actually, I'm struggling with..."

See what happens. Vulnerability invites connection.""",

      """THE TRUTH MIRROR

This week you used "I'm fine" variations several times.

Your most recent masked moment:
On $recentDate, you told $recentFrom: "$recentQuote"

${mostFrequentPerson != null ? 'You do this most with ${mostFrequentPerson.key}. Why?\n\n' : ''}The truth:
Every time you hide your truth, you're teaching them they can't handle the real you. 

But what if they can?

What if honesty doesn't push people away—it pulls them closer?

Try this:
The next time you want to say "I'm fine," pause. Take a breath. Then say one real thing about how you actually feel.

Start small. "Actually, I'm feeling overwhelmed today." Or "I'm not okay, but I'm trying."

Watch what happens. Most people respond better to honesty than masks.""",
      
      """THE TRUTH MIRROR

Your pattern this week:

You wore the mask. Multiple times. You said you were fine when you weren't.

Last instance:
$recentDate — "$recentQuote" (to $recentFrom)

${mostFrequentPerson != null ? 'You do this frequently with ${mostFrequentPerson.key}.\n\n' : ''}The insight:
You're not alone in this. Everyone does it. But awareness is the first step toward change.

Why you do it:
- You don't want to burden them
- You think they can't handle it
- You've learned vulnerability means hurt

But here's what matters:
Every hidden truth moves you one step away from real connection.

The experiment:
Pick one person this week. Stop hiding with them. Just one person. See what changes.

The mask feels safe. But safety isn't the same as connection.""",
    ];
    
    return templates[_random.nextInt(templates.length)];
  }

  /// Generate Strength Mirror response - Dynamic and data-driven  
  String _generateStrengthResponse(String lifeLogContent) {
    final entries = _parseLifeLog(lifeLogContent);
    final now = DateTime.now();
    
    // Analyze this week vs last week for trends
    final thisWeekEntries = entries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    final lastWeekEntries = entries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 14))) &&
             date.isBefore(now.subtract(const Duration(days: 7)));
    }).toList();
    
    // Deep pattern analysis - look for success patterns
    final positiveKeywords = ['completed', 'finished', 'done', 'achieved', 'succeeded', 'won', 'accomplished', 'nailed', 'crushed', 'smashed', 'mastered', 'finished', 'delivered', 'closed', 'finalized'];
    final achievementEntries = <Map<String, dynamic>>[];
    final activityPatterns = <String, List<Map<String, dynamic>>>{};
    
      for (final entry in entries.reversed.take(100)) { // Analyze recent 100 entries
      final text = ((entry['body'] as String?) ?? (entry['text'] as String?) ?? (entry['message'] as String?))?.toLowerCase() ?? '';
      final originalText = (entry['body'] as String?) ?? (entry['text'] as String?) ?? (entry['message'] as String?) ?? '';
      
      for (final keyword in positiveKeywords) {
        if (text.contains(keyword)) {
          achievementEntries.add(entry);
          
          // Extract context words around the keyword
          final words = text.split(' ');
          final keywordIndex = words.indexOf(keyword);
          if (keywordIndex > 0) {
            final context = words.sublist(max(0, keywordIndex - 2), min(words.length, keywordIndex + 3)).join(' ');
            if (context.length > 10) {
              activityPatterns.putIfAbsent(context, () => []).add(entry);
            }
          }
          break;
        }
      }
    }
    
    final thisWeekAchievements = achievementEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).length;
    
    if (activityPatterns.isEmpty && thisWeekEntries.isNotEmpty) {
      final templates = [
        """THE STRENGTH MIRROR

This week you captured moments of awareness.

Your strength isn't in the big wins—it's in the showing up.

Every entry you made this week is evidence of something important: you're choosing awareness over autopilot.

Most people never bother to look at themselves. You're doing it consistently.

The pattern:
Consistency. Showing up. Paying attention.

These don't sound like strengths, but they're the foundation of everything else.

What this means:
You're building something. Every moment you track is a brick in the foundation.

Keep going. The strength is in the accumulation.""",
        
        """THE STRENGTH MIRROR

This week you logged entries consistently.

Your hidden superpower:
You show up. Even when it's hard. Even when you don't feel like it.

Most people start tracking their life, get excited, then stop after a few days.

You're still here. That's strength.

Why this matters:
The ability to consistently show up for yourself is rare. Most people can't do it.

You're building the muscle of self-awareness. Every entry strengthens it.

The truth:
The real strength isn't in the big dramatic moments. It's in the daily choice to face yourself.

Keep tracking. Keep showing up. That's your power.""",
      ];
      
      return templates[_random.nextInt(templates.length)];
    }
    
    // Find top activity pattern
    final topPattern = activityPatterns.entries.isEmpty 
        ? null 
        : activityPatterns.entries.reduce((a, b) => a.value.length > b.value.length ? a : b);
    
    if (topPattern == null) {
      return """THE STRENGTH MIRROR

Your strength is becoming clear.

This week you achieved things. You completed tasks. You made progress.

The insight:
Your strength is in the tracking itself. The awareness. The consistency.

When you show up for yourself consistently, you build momentum.

Keep going. The patterns will reveal themselves.""";
    }
    
    final recentWin = topPattern.value.isNotEmpty 
        ? topPattern.value.first 
        : null;
    final recentWinTextRaw = recentWin != null
        ? ((recentWin['body'] ?? recentWin['text'] ?? recentWin['message']) as String? ?? '')
        : '';
    final recentWinText = recentWinTextRaw.length > 80
        ? '${recentWinTextRaw.substring(0, 80)}...'
        : recentWinTextRaw;
    
    final templates = [
      """THE STRENGTH MIRROR

Your secret weapon discovered:

When you "${topPattern.key}", you win.

This pattern has led to success multiple times. It's not luck. It's alignment.

Recent example:
"$recentWinText"

Why this works:
This pattern taps into something deep in you. It's not random. It's who you are when you're at your best.

Your task:
Do more of this. Intentionally. Systematically.

Make "${topPattern.key}" your default move. Schedule it. Prioritize it.

The pattern doesn't lie. Use it.""",
      
      """THE STRENGTH MIRROR

Your strength revealed:

"${topPattern.key}" — This is your winning formula.

This pattern has shown up consistently in your successes. When you do this, you succeed.

Most recent win:
"$recentWinText"

The insight:
This isn't random. This is a pattern. When you do this, you succeed.

The question:
If you know this works, why don't you do it more?

The answer:
Make it non-negotiable. Build your day around it. This is your unfair advantage.

Use it.""",
    ];
    
    return templates[_random.nextInt(templates.length)];
  }

  /// Generate Shadow Mirror response - Dynamic and data-driven
  /// Analyzes ALL data sources: photos, health, location, calendar, contacts, reminders, notes, audio, app usage, communications
  String _generateShadowResponse(String lifeLogContent) {
    final entries = _parseLifeLog(lifeLogContent);
    final now = DateTime.now();
    
    // Filter entries with valid dates
    final validEntries = entries.where((e) {
      if (e['date'] == null) return false;
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.year > 2000;
    }).toList();
    
    // Categorize entries by type to analyze all data sources
    final photoEntries = validEntries.where((e) => e['type'] == 'photo').toList();
    final healthEntries = validEntries.where((e) => e['type'] != null && (e['type'] as String).startsWith('health_')).toList();
    final locationEntries = validEntries.where((e) => e['type'] == 'location').toList();
    final calendarEntries = validEntries.where((e) => e['type'] == 'calendar_event').toList();
    final reminderEntries = validEntries.where((e) => e['type'] == 'reminder').toList();
    final textEntries = validEntries.where((e) {
      final hasText = e['body'] != null || e['text'] != null || e['message'] != null;
      final isCommunication = e['type'] == 'journal';
      return hasText || isCommunication;
    }).toList();
    
    final thisWeekEntries = validEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    // Analyze avoidance patterns across ALL data sources
    
    // 1. Calendar cancellations/missed events
    final calendarAvoidance = _analyzeCalendarAvoidance(calendarEntries, thisWeekEntries);
    if (calendarAvoidance != null) return calendarAvoidance;
    
    // 2. Health pattern avoidance (declining activity)
    final healthAvoidance = _analyzeHealthAvoidance(healthEntries, thisWeekEntries);
    if (healthAvoidance != null) return healthAvoidance;
    
    // 3. Location avoidance (staying in one place, not showing up)
    final locationAvoidance = _analyzeLocationAvoidance(locationEntries, calendarEntries, thisWeekEntries);
    if (locationAvoidance != null) return locationAvoidance;
    
    // 4. Reminder avoidance (not completing reminders)
    final reminderAvoidance = _analyzeReminderAvoidance(reminderEntries, thisWeekEntries);
    if (reminderAvoidance != null) return reminderAvoidance;
    
    // Fallback: Analyze text for avoidance keywords
    final avoidanceKeywords = ['later', 'tomorrow', 'maybe', 'probably', 'can\'t', 'busy', 'tired', 'sorry', 'can not', 'unable', 'unavailable', 'not now', 'some other time'];
    final avoidanceEntries = <Map<String, dynamic>>[];
    final avoidanceTriggers = <String, List<Map<String, dynamic>>>{};
    
    for (final entry in textEntries.reversed.take(100)) {
      final text = ((entry['body'] as String?) ?? (entry['text'] as String?) ?? (entry['message'] as String?))?.toLowerCase() ?? '';
      final originalText = (entry['body'] as String?) ?? (entry['text'] as String?) ?? (entry['message'] as String?) ?? '';
      
      for (final keyword in avoidanceKeywords) {
        if (text.contains(keyword)) {
          avoidanceEntries.add(entry);
          
          if (text.contains('when') || text.contains('because') || text.contains('if') || text.contains('since')) {
            final parts = text.split(RegExp(r'when|because|if|since'));
            if (parts.length > 1) {
              final trigger = parts[1].trim().split(RegExp(r'[.,!?]')).first.trim();
              if (trigger.length > 5 && trigger.length < 50) {
                avoidanceTriggers.putIfAbsent(trigger, () => []).add(entry);
              }
            }
          }
          break;
        }
      }
    }
    
    final thisWeekAvoidance = avoidanceEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).length;
    
    if (thisWeekAvoidance == 0 && thisWeekEntries.isNotEmpty) {
      final templates = [
        """THE SHADOW MIRROR

This week you showed up.

You didn't run. You didn't hide. You faced what needed facing.

The truth:
Most people have significant avoidance patterns. The fact that yours are minimal this week means you're doing the work.

Stay vigilant:
Avoidance is sneaky. It creeps in when you're tired, stressed, or afraid.

Keep watching. Keep tracking.

Awareness is your shield.""",
        
        """THE SHADOW MIRROR

No major avoidance patterns detected this week.

This is rare. Most people run from difficult things. You're facing them.

What this means:
You're building the muscle of presence. You're choosing to show up even when it's hard.

The shadow loses power when you shine light on it. Keep shining.

Stay aware. The shadow always finds new ways to hide.""",
      ];
      
      return templates[_random.nextInt(templates.length)];
    }
    
    final topTrigger = avoidanceTriggers.isEmpty 
        ? null 
        : avoidanceTriggers.entries.reduce((a, b) => a.value.length > b.value.length ? a : b);
    
    final recentAvoidance = avoidanceEntries.isNotEmpty 
        ? avoidanceEntries.first 
        : null;
    final recentQuoteRaw = recentAvoidance != null
        ? ((recentAvoidance['body'] ?? recentAvoidance['text'] ?? recentAvoidance['message']) as String? ?? '')
        : '';
    final recentQuote = recentQuoteRaw.length > 100
        ? '${recentQuoteRaw.substring(0, 100)}...'
        : recentQuoteRaw;
    final recentDate = recentAvoidance != null && recentAvoidance['date'] != null
        ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(recentAvoidance['date'] as int))
        : 'recently';
    final recentFrom = recentAvoidance?['from'] ?? 'someone';
    
    final templates = [
      """THE SHADOW MIRROR

Your avoidance pattern this week:

You chose avoidance over presence. Multiple times.

Most recent escape:
$recentDate
To $recentFrom: "$recentQuote"

${topTrigger != null ? 'The trigger: "${topTrigger.key}"\nWhen you feel this, you tend to avoid.\n\n' : ''}Why this happens:
Avoidance feels safe. But it's an illusion. Every avoidance creates distance.

The cost:
- Less connection
- More isolation  
- Stronger patterns of escape

The solution:
Next time you feel ${topTrigger != null ? '"${topTrigger.key}"' : 'the urge to avoid'}, pause. Take 3 breaths. Then choose presence.

The shadow loses power when you face it.""",
      
      """THE SHADOW MIRROR

Your shadow showed up this week.

You avoided. You escaped. You ran from something.

Latest instance:
$recentDate — "$recentQuote" (to $recentFrom)

${topTrigger != null ? 'Pattern identified: You avoid when "${topTrigger.key}"\n\n' : ''}The insight:
Your shadow protects you by running. But running doesn't make you safe—it makes you alone.

The experiment:
Next time ${topTrigger != null ? 'you feel "${topTrigger.key}"' : 'you want to avoid'}, don't.

Instead:
1. Notice the feeling
2. Name it out loud
3. Take 3 deep breaths
4. Choose presence anyway

The shadow can't survive in the light. Face it.""",
    ];
    
    return templates[_random.nextInt(templates.length)];
  }

  /// Generate Growth Mirror response - Dynamic and data-driven
  String _generateGrowthResponse(String lifeLogContent) {
    final entries = _parseLifeLog(lifeLogContent);
    final now = DateTime.now();
    
    // Filter out invalid dates (year 1970 or missing dates)
    final validEntries = entries.where((e) {
      if (e['date'] == null) return false;
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.year > 2000;
    }).toList();
    
    // Time-based comparison
    final thisWeekEntries = validEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    final lastWeekEntries = validEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 14))) &&
             date.isBefore(now.subtract(const Duration(days: 7)));
    }).toList();
    
    final thisWeek = thisWeekEntries.length;
    final lastWeek = lastWeekEntries.length;
    
    // Determine improvement qualitatively without numbers
    final hasImprovement = thisWeek > lastWeek || (thisWeek > 0 && lastWeek == 0);
    final hasDecline = thisWeek < lastWeek && lastWeek > 0;
    
    // Analyze activity types
    final thisWeekTypes = <String, int>{};
    final lastWeekTypes = <String, int>{};
    
    for (final entry in thisWeekEntries) {
      final type = entry['type'] as String? ?? 'unknown';
      thisWeekTypes[type] = (thisWeekTypes[type] ?? 0) + 1;
    }
    
    for (final entry in lastWeekEntries) {
      final type = entry['type'] as String? ?? 'unknown';
      lastWeekTypes[type] = (lastWeekTypes[type] ?? 0) + 1;
    }
    
    // Find fastest growing area qualitatively
    String? fastestGrowthArea;
    int maxGrowthDifference = 0;
    for (final type in thisWeekTypes.keys) {
      if (type == 'unknown') continue;
      final thisCount = thisWeekTypes[type] ?? 0;
      final lastCount = lastWeekTypes[type] ?? 0;
      if (thisCount > lastCount) {
        final growthDiff = thisCount - lastCount;
        if (growthDiff > maxGrowthDifference) {
          maxGrowthDifference = growthDiff;
          fastestGrowthArea = type;
        }
      }
    }
    
    if (!hasImprovement && thisWeek > 0) {
      final templates = [
        """THE GROWTH MIRROR

This week compared to last week:

You're showing up consistently. The pace might feel the same, but that's okay.

Growth isn't always linear. Sometimes you consolidate. Sometimes you process. Sometimes you prepare for the next leap.

The real growth:
Are you more aware? More intentional? More honest with yourself?

Those are the metrics that matter.

Quality over quantity. Depth over volume.

Keep showing up.""",
        
        """THE GROWTH MIRROR

This week you tracked consistently.

The surface might feel the same. But look deeper.

Growth isn't just about pace. It's about:
- Awareness
- Intentionality
- Honesty with yourself

If you're tracking more thoughtfully, that's growth.
If you're seeing patterns more clearly, that's growth.
If you're being more honest, that's growth.

Focus on the quality. The depth matters more than the volume.""",
      ];
      
      return templates[_random.nextInt(templates.length)];
    }
    
    // Handle case when there are no entries
    if (thisWeek == 0 && validEntries.isEmpty) {
      return """THE GROWTH MIRROR

Starting point identified.

This is your first week. Every journey begins with a single step.

Your foundation:
You are building the habit of self-awareness. That is already growth.

What is next:
Track consistently. Show up daily. The patterns will emerge.

Be patient. Growth takes time.""";
    }
    
    // If we have entries but no entries this week, analyze overall progress
    if (thisWeek == 0 && validEntries.isNotEmpty) {
      // Sort entries by date to get oldest and newest
      validEntries.sort((a, b) {
        final dateA = DateTime.fromMillisecondsSinceEpoch(a['date'] as int? ?? 0);
        final dateB = DateTime.fromMillisecondsSinceEpoch(b['date'] as int? ?? 0);
        return dateA.compareTo(dateB);
      });
      
      // Analyze entry types qualitatively
      final entryTypes = <String, int>{};
      for (final entry in validEntries) {
        final type = entry['type'] as String? ?? 'unknown';
        entryTypes[type] = (entryTypes[type] ?? 0) + 1;
      }
      final topType = entryTypes.entries.isEmpty 
          ? null 
          : entryTypes.entries.reduce((a, b) => a.value > b.value ? a : b);
      
      final templates = [
        """THE GROWTH MIRROR

Your tracking foundation:

You've been building awareness. You have a foundation of moments captured.

${topType != null ? 'You track ${topType.key} most often.\n\n' : ''}This week: No new entries

What this means:
You have been building something. You are accumulating awareness.

This week might be quiet, but that is okay. Growth is not always about new entries.

Sometimes you are:
- Processing what you have learned
- Consolidating insights
- Preparing for the next phase

The patterns are forming. The awareness is building. The insights are coming.

Keep showing up. The growth will reveal itself in time.""",
        
        """THE GROWTH MIRROR

You've been tracking consistently.

You have accumulated moments of awareness. You are building something real.

${topType != null ? 'Your primary focus is ${topType.key}.\n\n' : ''}This week: No new entries tracked

The insight:
This week is quiet, but quiet does not mean stagnant.

Growth happens in layers:
1. Accumulation (you are here)
2. Recognition (patterns emerge)
3. Transformation (patterns change)

You are building the foundation. Every entry matters.

Trust the process. Keep tracking when you can.""",
      ];
      
      return templates[_random.nextInt(templates.length)];
    }
    
    final templates = [
      """THE GROWTH MIRROR

This week you are moving forward.

You tracked more than last week. You're showing up more consistently.

${fastestGrowthArea != null ? "You're expanding most in $fastestGrowthArea.\n\n" : ''}What this means:
You are growing. Clearly. Consistently.

The momentum is building. Something is clicking. Keep riding this wave.

The insight:
Most people plateau. You are growing.

Keep going. The best is yet to come.""",
      
      """THE GROWTH MIRROR

This week compared to last week:

You're evolving. You're not stuck. You're not stagnant.

${fastestGrowthArea != null ? "You're expanding fastest in $fastestGrowthArea.\n\n" : ''}The truth:
Look beyond the pace. Ask yourself:
- Are you more honest?
- Are you more aware?
- Are you more intentional?

That's the real growth. That's what matters.

Keep evolving.""",
    ];
    
    return templates[_random.nextInt(templates.length)];
  }

  /// Generate Legacy Mirror response - Dynamic and data-driven
  /// Analyzes ALL data sources: photos, health, location, calendar, contacts, reminders, notes, audio, app usage, communications
  String _generateLegacyResponse(String lifeLogContent) {
    final entries = _parseLifeLog(lifeLogContent);
    final now = DateTime.now();
    
    // Filter entries with valid dates
    final validEntries = entries.where((e) {
      if (e['date'] == null) return false;
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.year > 2000;
    }).toList();
    
    // Categorize entries by type to analyze all data sources
    final photoEntries = validEntries.where((e) => e['type'] == 'photo').toList();
    final healthEntries = validEntries.where((e) => e['type'] != null && (e['type'] as String).startsWith('health_')).toList();
    final locationEntries = validEntries.where((e) => e['type'] == 'location').toList();
    final calendarEntries = validEntries.where((e) => e['type'] == 'calendar_event').toList();
    final contactEntries = validEntries.where((e) => e['type'] == 'contact').toList();
    final reminderEntries = validEntries.where((e) => e['type'] == 'reminder').toList();
    final noteEntries = validEntries.where((e) => e['type'] == 'note').toList();
    final textEntries = validEntries.where((e) {
      final hasText = e['body'] != null || e['text'] != null || e['message'] != null;
      final isCommunication = e['type'] == 'journal';
      return hasText || isCommunication;
    }).toList();
    
    // Analyze this week's themes across ALL data sources
    final weekEntries = validEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    // Enhanced theme detection across all data types
    
    // 1. Analyze themes from calendar (scheduled priorities)
    final calendarThemes = _analyzeCalendarThemes(calendarEntries, weekEntries);
    if (calendarThemes != null) return calendarThemes;
    
    // 2. Analyze themes from health data (fitness, wellness, activity)
    final healthThemes = _analyzeHealthThemes(healthEntries, weekEntries);
    if (healthThemes != null) return healthThemes;
    
    // 3. Analyze themes from location (places you return to)
    final locationThemes = _analyzeLocationThemes(locationEntries, weekEntries);
    if (locationThemes != null) return locationThemes;
    
    // 4. Analyze themes from photos (what you document)
    final photoThemes = _analyzePhotoThemes(photoEntries, weekEntries);
    if (photoThemes != null) return photoThemes;
    
    // Fallback: Analyze text for theme keywords
    final keywords = ['love', 'work', 'family', 'health', 'growth', 'challenge', 'connection', 'purpose', 'struggle', 'joy', 'pain', 'breakthrough', 'relationship', 'career', 'fitness', 'learning', 'friendship', 'adventure', 'peace', 'conflict'];
    final themes = <String, int>{};
    final themeEntries = <String, List<Map<String, dynamic>>>{};
    
    for (final entry in textEntries.where((e) => weekEntries.contains(e))) {
      final text = ((entry['body'] as String?) ?? (entry['text'] as String?) ?? (entry['message'] as String?))?.toLowerCase() ?? '';
      for (final keyword in keywords) {
        if (text.contains(keyword)) {
          themes[keyword] = (themes[keyword] ?? 0) + 1;
          themeEntries.putIfAbsent(keyword, () => []).add(entry);
        }
      }
    }
    
    if (themes.isEmpty && weekEntries.isNotEmpty) {
      final templates = [
        """THE LEGACY MIRROR

Looking back from 2065:

This week will be remembered as: The Week of Quiet Observation.

You watched. You noticed. You paid attention.

Not every week needs drama. Sometimes the most important work happens in silence.

Your legacy:
You showed up. You tracked. You remained aware.

That consistency - that's your legacy.

What seeds are you planting now that will bloom in 40 years?""",
        
        """THE LEGACY MIRROR

Future perspective (2065):

This week: The Week of Silent Growth.

No major themes. No dramatic events. Just presence. Just awareness.

The legacy:
Sometimes the quiet weeks matter most. They're the foundation.

You showed up. That's enough.

Your future self is watching. They're proud.""",
      ];
      
      return templates[_random.nextInt(templates.length)];
    }
    
    if (themes.isEmpty) {
      return """THE LEGACY MIRROR

The Week of Beginning.

Every legacy starts somewhere. This is your starting point.

What will this week become in 40 years?

Only time will tell. But you've started the journey.

That's what matters.""";
    }
    
    final topTheme = themes.entries.reduce((a, b) => a.value > b.value ? a : b);
    final themeEntriesList = themeEntries[topTheme.key] ?? [];
    final sampleEntry = themeEntriesList.isNotEmpty 
        ? themeEntriesList[themeEntriesList.length ~/ 2] 
        : null;
    final sampleTextRaw = sampleEntry != null
        ? ((sampleEntry['body'] ?? sampleEntry['text'] ?? sampleEntry['message']) as String? ?? '')
        : '';
    final sampleText = sampleTextRaw.length > 90
        ? '${sampleTextRaw.substring(0, 90)}...'
        : sampleTextRaw;
    
    final legacyMessage = {
      'love': 'You chose connection. Intimacy. Opening your heart.',
      'work': 'You chose purpose. Impact. Building something.',
      'family': 'You chose your people. Showing up. Being present.',
      'health': 'You chose yourself. Your body. Your care.',
      'growth': 'You chose evolution. Learning. Becoming more.',
      'challenge': 'You chose to face it. Not run. Courage.',
      'connection': 'You chose relationship. Depth. Real contact.',
      'purpose': 'You chose meaning. Direction. Intention.',
      'struggle': 'You chose to engage with difficulty. Not hide.',
      'joy': 'You chose to notice happiness. To celebrate it.',
      'pain': 'You chose to feel it. To process it.',
      'breakthrough': 'You chose to push through. To transform.',
    }[topTheme.key] ?? 'You chose to focus. Intentionality. Presence.';
    
    final templates = [
      """THE LEGACY MIRROR

Looking back from 2065:

This week will be remembered as: The Week of ${topTheme.key.toUpperCase()}.

This week you focused deeply on ${topTheme.key}. That was your theme. Your pattern. Your choice.

A sample from the week:
"$sampleText"

The legacy:
$legacyMessage

That's what you'll remember. That's what will matter.

The question:
When you're 65, what will this week have built? What will it have taught you?

The answer:
Only you can decide. But you've already started by noticing. By tracking. By being aware.

Every moment is a seed. This week, you planted many.

Make them count.""",
      
      """THE LEGACY MIRROR

Future perspective (2065):

This week: The Week You Focused On ${topTheme.key.toUpperCase()}.

This week was about ${topTheme.key}. That was your focus. Your intention. Your legacy.

Example moment:
"$sampleText"

What this means:
$legacyMessage

That's your legacy. That's what will matter.

In 40 years:
You won't remember the exact words. You'll remember the feeling. The intention. The focus.

Make it count. This week is a chapter in your story.

Keep writing.""",
    ];
    
    return templates[_random.nextInt(templates.length)];
  }

  /// Default response generator
  String _generateDefaultResponse(String lifeLogContent) {
    // lifeLogContent is available if needed for future enhancements
    return "Your moments have been reviewed.\n\nPattern detected: You document your experiences consistently.";
  }

  /// Parse life log JSONL content
  List<Map<String, dynamic>> _parseLifeLog(String content) {
    if (content.trim().isEmpty) return [];
    
    final lines = content.split('\n');
    final entries = <Map<String, dynamic>>[];
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final parsed = _parseJsonLine(line);
        if (parsed.isNotEmpty) {
          entries.add(parsed);
        }
      } catch (e) {
        // Skip invalid lines
      }
    }
    
    return entries;
  }

  /// Simple JSON line parser
  Map<String, dynamic> _parseJsonLine(String line) {
    try {
      // Try proper JSON parsing first
      final decoded = _tryParseJson(line);
      if (decoded != null) return decoded;
    } catch (e) {
      // Fall back to regex parsing
    }
    
    // Fallback: regex-based parsing
    final result = <String, dynamic>{};
    
    final typeMatch = RegExp(r'"type"\s*:\s*"([^"]+)"').firstMatch(line);
    if (typeMatch != null) result['type'] = typeMatch.group(1);
    
    final bodyMatch = RegExp(r'"body"\s*:\s*"([^"]+)"').firstMatch(line);
    if (bodyMatch != null) result['body'] = bodyMatch.group(1);
    
    final textMatch = RegExp(r'"text"\s*:\s*"([^"]+)"').firstMatch(line);
    if (textMatch != null) result['text'] = textMatch.group(1);
    
    final messageMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(line);
    if (messageMatch != null) result['message'] = messageMatch.group(1);
    
    final fromMatch = RegExp(r'"from"\s*:\s*"([^"]+)"').firstMatch(line);
    if (fromMatch != null) result['from'] = fromMatch.group(1);
    
    final dateMatch = RegExp(r'"date"\s*:\s*(\d+)').firstMatch(line);
    if (dateMatch != null) result['date'] = int.tryParse(dateMatch.group(1) ?? '0') ?? 0;
    
    // Also check for timestamp if date is missing
    if (result['date'] == null || result['date'] == 0) {
      final timestampMatch = RegExp(r'"timestamp"\s*:\s*"([^"]+)"').firstMatch(line);
      if (timestampMatch != null) {
        try {
          final timestamp = DateTime.parse(timestampMatch.group(1)!);
          result['date'] = timestamp.millisecondsSinceEpoch;
        } catch (e) {
          // Ignore parse errors
        }
      }
    }
    
    return result;
  }

  /// Try to parse JSON properly
  Map<String, dynamic>? _tryParseJson(String line) {
    try {
      return jsonDecode(line) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Format date from timestamp
  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'recently';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.month}/${date.day}';
    } catch (e) {
      return 'recently';
    }
  }

  /// Format detailed date
  String _formatDetailedDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} minutes ago';
      }
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${weekdays[date.weekday - 1]} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Analyze location patterns - where you are vs where you planned to be
  String? _analyzeLocationPattern(List<Map<String, dynamic>> locationEntries, List<Map<String, dynamic>> calendarEntries, List<Map<String, dynamic>> thisWeekEntries) {
    if (locationEntries.isEmpty) return null;
    
    final now = DateTime.now();
    final recentLocations = locationEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    if (recentLocations.isEmpty) return null;
    
    // Group locations by common areas (simplified - would need geocoding for real addresses)
    final locationPatterns = <String, int>{};
    for (final loc in recentLocations) {
      final lat = (loc['latitude'] as num?)?.toDouble();
      final lon = (loc['longitude'] as num?)?.toDouble();
      if (lat != null && lon != null) {
        // Round to approximate location (within ~1km)
        final key = '${lat.toStringAsFixed(1)},${lon.toStringAsFixed(1)}';
        locationPatterns[key] = (locationPatterns[key] ?? 0) + 1;
      }
    }
    
    if (locationPatterns.isEmpty) return null;
    
    final mostFrequentLocation = locationPatterns.entries.reduce((a, b) => a.value > b.value ? a : b);
    final lastLocation = recentLocations.first;
    final lastLocationDate = lastLocation['date'] != null
        ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastLocation['date'] as int))
        : 'recently';
    
    return """THE TRUTH MIRROR

This week reveals where you actually spend your time.

Your patterns show you return to certain places repeatedly. This isn't coincidence. It's choice.

The data shows:
You were at the same location multiple times this week. That place matters to you.

Your most recent visit:
$lastLocationDate

What this means:
Where you are is who you are becoming. Your location choices shape your experiences, your connections, your life.

The truth:
Every place you go, you're making a choice. Every location, a reflection of what you value.

Pay attention to where you're drawn. It's telling you something about yourself.

Where you spend time shapes who you become.""";
  }

  /// Analyze activity patterns - what you do vs what you plan
  String? _analyzeActivityPattern(List<Map<String, dynamic>> healthEntries, List<Map<String, dynamic>> calendarEntries, List<Map<String, dynamic>> appUsageEntries, List<Map<String, dynamic>> thisWeekEntries) {
    final now = DateTime.now();
    
    // Analyze health activity
    final recentHealth = healthEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    // Analyze calendar vs actual activity
    final scheduledEvents = calendarEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    if (recentHealth.isEmpty && scheduledEvents.isEmpty) return null;
    
    final lastHealth = recentHealth.isNotEmpty ? recentHealth.first : null;
    final lastEvent = scheduledEvents.isNotEmpty ? scheduledEvents.first : null;
    
    if (lastHealth != null) {
      final healthType = (lastHealth['type'] as String? ?? '').replaceAll('health_', '');
      final healthDate = lastHealth['date'] != null
          ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastHealth['date'] as int))
          : 'recently';
      
      return """THE TRUTH MIRROR

This week shows what you actually do.

Your body tells a story. Your health data, your activities, your movements reveal patterns you might not notice.

The pattern:
You're tracking your ${healthType}. This matters to you.

Most recent activity:
$healthDate

What this means:
What you measure, you manage. What you track, you improve.

The truth:
Your actions speak louder than your plans. Your body knows what you're really doing, even when your mind doesn't.

Pay attention to what your data shows. It's revealing who you're becoming.

What you do defines who you are.""";
    }
    
    if (lastEvent != null) {
      final eventTitle = (lastEvent['title'] as String? ?? 'your event');
      final eventDate = lastEvent['date'] != null
          ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastEvent['date'] as int))
          : 'recently';
      
      return """THE TRUTH MIRROR

This week reveals how you spend your time.

Your calendar shows your intentions. Your reality shows your truth.

The event:
"$eventTitle" on $eventDate

What this means:
Every event you schedule is a choice. Every commitment, a reflection of what matters to you.

The truth:
Your calendar is a mirror of your priorities. Not what you say matters, but what you actually schedule.

Pay attention to how you spend your time. It's showing you what you truly value.

Your time is your truth.""";
    }
    
    return null;
  }

  /// Analyze social patterns - who you interact with
  String? _analyzeSocialPattern(List<Map<String, dynamic>> contactEntries, List<Map<String, dynamic>> calendarEntries, List<Map<String, dynamic>> textEntries, List<Map<String, dynamic>> thisWeekEntries) {
    if (contactEntries.isEmpty && calendarEntries.isEmpty) return null;
    
    final now = DateTime.now();
    
    // Analyze contacts
    final recentContacts = contactEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    // Analyze calendar attendees
    final eventsWithPeople = calendarEntries.where((e) {
      final attendees = e['attendees'];
      return attendees != null && (attendees is List) && (attendees as List).isNotEmpty;
    }).toList();
    
    if (recentContacts.isEmpty && eventsWithPeople.isEmpty) return null;
    
    final lastContact = recentContacts.isNotEmpty ? recentContacts.first : null;
    final lastEvent = eventsWithPeople.isNotEmpty ? eventsWithPeople.first : null;
    
    if (lastContact != null) {
      final contactName = (lastContact['name'] as String? ?? 'someone');
      final contactDate = lastContact['date'] != null
          ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastContact['date'] as int))
          : 'recently';
      
      return """THE TRUTH MIRROR

This week shows who you're connected to.

Your contacts reveal your social patterns. Who you interact with, who you keep close, who matters to you.

The pattern:
You're connected to $contactName.

Most recent contact:
$contactDate

What this means:
Your relationships shape your reality. Who you spend time with is who you're becoming.

The truth:
You're the average of the people you surround yourself with. Your connections define your direction.

Pay attention to who you're drawn to. It's telling you something about yourself.

Who you connect with shapes who you become.""";
    }
    
    return null;
  }

  /// Analyze time patterns - how you spend time
  String? _analyzeTimePattern(List<Map<String, dynamic>> calendarEntries, List<Map<String, dynamic>> appUsageEntries, List<Map<String, dynamic>> locationEntries, List<Map<String, dynamic>> thisWeekEntries) {
    final now = DateTime.now();
    
    // Analyze app usage patterns
    final recentAppUsage = appUsageEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    if (recentAppUsage.isEmpty) return null;
    
    final appUsagePatterns = <String, int>{};
    for (final entry in recentAppUsage) {
      final appName = entry['appName'] as String? ?? 'unknown';
      final duration = entry['duration'] as int? ?? 0;
      appUsagePatterns[appName] = (appUsagePatterns[appName] ?? 0) + duration;
    }
    
    if (appUsagePatterns.isEmpty) return null;
    
    final topApp = appUsagePatterns.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    return """THE TRUTH MIRROR

This week shows how you actually spend your time.

Your app usage reveals what you focus on. Where your attention goes, your energy flows.

The pattern:
You spend significant time with ${topApp.key}. That's where your focus goes.

What this means:
Your attention is your most valuable resource. Where you focus, you grow.

The truth:
Every moment on your device is a choice. Every app, a reflection of what you value.

Pay attention to where your time goes. It's showing you what you truly care about.

Your time is your truth.""";
  }

  /// Analyze documentation patterns - what you capture vs what you experience
  String? _analyzeDocumentationPattern(List<Map<String, dynamic>> photoEntries, List<Map<String, dynamic>> locationEntries, List<Map<String, dynamic>> textEntries, List<Map<String, dynamic>> thisWeekEntries) {
    final now = DateTime.now();
    
    // Analyze photo patterns
    final recentPhotos = photoEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    if (recentPhotos.isEmpty) return null;
    
    final lastPhoto = recentPhotos.first;
    final lastPhotoDate = lastPhoto['date'] != null
        ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastPhoto['date'] as int))
        : 'recently';
    
    return """THE TRUTH MIRROR

This week shows what you choose to capture.

Your photos reveal what matters to you. What you document, you remember. What you remember, you honor.

The pattern:
You're capturing moments. You're documenting your life.

Most recent capture:
$lastPhotoDate

What this means:
Every photo is a choice. Every moment you capture is a moment you're choosing to remember.

The truth:
What you photograph is what you value. What you document is what you want to keep.

Pay attention to what you capture. It's showing you what you truly cherish.

What you document shapes what you remember.""";
  }

  // ========== STRENGTH MIRROR HELPER METHODS ==========
  
  /// Analyze health strength patterns
  String? _analyzeHealthStrength(List<Map<String, dynamic>> healthEntries, List<Map<String, dynamic>> thisWeekEntries) {
    final now = DateTime.now();
    final recentHealth = healthEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    if (recentHealth.isEmpty) return null;
    
    final healthTypes = <String, int>{};
    for (final entry in recentHealth) {
      final type = (entry['type'] as String? ?? '').replaceAll('health_', '');
      healthTypes[type] = (healthTypes[type] ?? 0) + 1;
    }
    
    if (healthTypes.isEmpty) return null;
    
    final topHealthType = healthTypes.entries.reduce((a, b) => a.value > b.value ? a : b);
    final lastHealth = recentHealth.first;
    final healthDate = lastHealth['date'] != null
        ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastHealth['date'] as int))
        : 'recently';
    
    return """THE STRENGTH MIRROR

Your strength revealed through your body:

This week you showed up for yourself physically. You tracked your ${topHealthType.key}. You made your health a priority.

Most recent activity:
$healthDate

What this means:
Your strength is in the consistency. The showing up. The tracking.

Most people ignore their body until it breaks. You're paying attention before it needs to.

The truth:
Physical strength reflects mental strength. When you take care of your body, you're taking care of your mind.

Your strength:
You choose awareness over avoidance. You choose tracking over ignoring.

Keep showing up for yourself. This is your power.""";
  }
  
  /// Analyze calendar strength patterns
  String? _analyzeCalendarStrength(List<Map<String, dynamic>> calendarEntries, List<Map<String, dynamic>> thisWeekEntries) {
    final now = DateTime.now();
    final recentEvents = calendarEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    if (recentEvents.isEmpty) return null;
    
    final lastEvent = recentEvents.first;
    final eventTitle = (lastEvent['title'] as String? ?? 'your commitments');
    final eventDate = lastEvent['date'] != null
        ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastEvent['date'] as int))
        : 'recently';
    
    return """THE STRENGTH MIRROR

Your strength revealed through your commitments:

This week you showed up. You scheduled things. You kept commitments.

Your events show your priorities. Your calendar shows your truth.

Most recent commitment:
"$eventTitle" on $eventDate

What this means:
Your strength is in the showing up. The keeping promises. The honoring commitments.

When you say you'll be somewhere, you're there. When you schedule something, you do it.

The truth:
Consistency builds strength. Every kept commitment strengthens you.

Your superpower:
You follow through. That's rare.

Keep showing up. Keep committing. Keep honoring your word.

That's your strength.""";
  }
  
  /// Analyze consistency strength patterns
  String? _analyzeConsistencyStrength(List<Map<String, dynamic>> photoEntries, List<Map<String, dynamic>> noteEntries, List<Map<String, dynamic>> textEntries, List<Map<String, dynamic>> thisWeekEntries, List<Map<String, dynamic>> lastWeekEntries) {
    final thisWeekTotal = thisWeekEntries.length;
    final lastWeekTotal = lastWeekEntries.length;
    
    if (thisWeekTotal == 0) return null;
    
    final hasConsistency = thisWeekTotal >= lastWeekTotal || (thisWeekTotal > 0 && lastWeekTotal == 0);
    
    if (hasConsistency) {
      final lastEntry = thisWeekEntries.first;
      final lastDate = lastEntry['date'] != null
          ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastEntry['date'] as int))
          : 'recently';
      
      return """THE STRENGTH MIRROR

Your strength is in the consistency:

This week you showed up for yourself consistently. You tracked. You documented. You stayed aware.

Most recent entry:
$lastDate

What this means:
Your strength isn't in the big dramatic moments. It's in the daily choice to show up.

Most people start tracking their life, get excited, then stop.

You're still here. That's strength.

The truth:
The real strength is in the accumulation. Every entry strengthens your self-awareness muscle.

Keep showing up. Keep tracking. Keep building.

That's your power.""";
    }
    
    return null;
  }
  
  /// Analyze location strength patterns
  String? _analyzeLocationStrength(List<Map<String, dynamic>> locationEntries, List<Map<String, dynamic>> calendarEntries, List<Map<String, dynamic>> thisWeekEntries) {
    final now = DateTime.now();
    final recentLocations = locationEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    if (recentLocations.isEmpty) return null;
    
    final lastLocation = recentLocations.first;
    final locationDate = lastLocation['date'] != null
        ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastLocation['date'] as int))
        : 'recently';
    
    return """THE STRENGTH MIRROR

Your strength revealed through your presence:

This week you showed up. You went places. You were present.

Where you are matters. Your location choices show your priorities.

Most recent location:
$locationDate

What this means:
Your strength is in the showing up. The being present. The choosing to be there.

When you show up physically, you show up mentally.

The truth:
Presence is a choice. You're choosing it.

Your strength:
You show up. That's everything.

Keep being present. Keep showing up.

That's your power.""";
  }

  // ========== SHADOW MIRROR HELPER METHODS ==========
  
  /// Analyze calendar avoidance patterns
  String? _analyzeCalendarAvoidance(List<Map<String, dynamic>> calendarEntries, List<Map<String, dynamic>> thisWeekEntries) {
    // If calendar is empty but you have other entries, might indicate avoidance of scheduling
    if (calendarEntries.isEmpty && thisWeekEntries.isNotEmpty) {
      return """THE SHADOW MIRROR

Your shadow showed up this week:

You avoided scheduling. You avoided commitments. You avoided structure.

The pattern:
No calendar events this week, but you're tracking other things.

What this means:
You might be avoiding the structure that commitments bring.

The shadow:
Avoidance feels safe. But it creates isolation. Every unscheduled day is a day you're not showing up.

The solution:
Start small. Schedule one thing. Show up for it.

The shadow loses power when you face it.""";
    }
    
    return null;
  }
  
  /// Analyze health avoidance patterns
  String? _analyzeHealthAvoidance(List<Map<String, dynamic>> healthEntries, List<Map<String, dynamic>> thisWeekEntries) {
    final now = DateTime.now();
    final recentHealth = healthEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    // If health tracking declined or stopped, might indicate avoidance
    if (thisWeekEntries.isNotEmpty && recentHealth.isEmpty) {
      return """THE SHADOW MIRROR

Your shadow showed up this week:

You avoided tracking your health. You avoided your body's signals.

The pattern:
You're tracking other things, but not your health.

What this means:
You might be avoiding what your body is telling you.

The shadow:
Ignoring your body doesn't make problems disappear. It makes them worse.

The solution:
Start small. Track one health metric. Pay attention.

The shadow loses power when you face it.""";
    }
    
    return null;
  }
  
  /// Analyze location avoidance patterns
  String? _analyzeLocationAvoidance(List<Map<String, dynamic>> locationEntries, List<Map<String, dynamic>> calendarEntries, List<Map<String, dynamic>> thisWeekEntries) {
    final now = DateTime.now();
    final recentLocations = locationEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    // If very few location changes, might indicate staying in comfort zone
    if (recentLocations.length < 3 && thisWeekEntries.length > 10) {
      return """THE SHADOW MIRROR

Your shadow showed up this week:

You stayed in your comfort zone. You avoided new places. You avoided movement.

The pattern:
You were mostly in one place. Minimal location changes.

What this means:
You might be avoiding the discomfort of new experiences.

The shadow:
Staying safe feels comfortable. But comfort zones shrink over time.

The solution:
Start small. Go somewhere new. Even briefly.

The shadow loses power when you face it.""";
    }
    
    return null;
  }
  
  /// Analyze reminder avoidance patterns
  String? _analyzeReminderAvoidance(List<Map<String, dynamic>> reminderEntries, List<Map<String, dynamic>> thisWeekEntries) {
    final now = DateTime.now();
    final recentReminders = reminderEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      final isCompleted = e['isCompleted'] as bool? ?? false;
      return date.isAfter(now.subtract(const Duration(days: 7))) && !isCompleted;
    }).toList();
    
    if (recentReminders.isEmpty) return null;
    
    final incompleteCount = recentReminders.length;
    final lastReminder = recentReminders.first;
    final reminderTitle = (lastReminder['title'] as String? ?? 'something');
    final reminderDate = lastReminder['date'] != null
        ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastReminder['date'] as int))
        : 'recently';
    
    return """THE SHADOW MIRROR

Your shadow showed up this week:

You avoided completing reminders. You avoided finishing tasks.

The pattern:
You have incomplete reminders. Tasks that you set but didn't finish.

Most recent incomplete:
"$reminderTitle" from $reminderDate

What this means:
You might be avoiding the discomfort of completion.

The shadow:
Unfinished tasks create mental clutter. They drain energy.

The solution:
Start small. Complete one reminder. Then another.

The shadow loses power when you face it.""";
  }

  // ========== LEGACY MIRROR HELPER METHODS ==========
  
  /// Analyze calendar themes
  String? _analyzeCalendarThemes(List<Map<String, dynamic>> calendarEntries, List<Map<String, dynamic>> weekEntries) {
    final now = DateTime.now();
    final recentEvents = calendarEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    if (recentEvents.isEmpty) return null;
    
    final eventThemes = <String, int>{};
    for (final event in recentEvents) {
      final title = ((event['title'] as String?) ?? '').toLowerCase();
      if (title.contains('work') || title.contains('meeting') || title.contains('project')) {
        eventThemes['work'] = (eventThemes['work'] ?? 0) + 1;
      }
      if (title.contains('family') || title.contains('family')) {
        eventThemes['family'] = (eventThemes['family'] ?? 0) + 1;
      }
      if (title.contains('health') || title.contains('workout') || title.contains('exercise')) {
        eventThemes['health'] = (eventThemes['health'] ?? 0) + 1;
      }
      if (title.contains('friend') || title.contains('social') || title.contains('party')) {
        eventThemes['connection'] = (eventThemes['connection'] ?? 0) + 1;
      }
    }
    
    if (eventThemes.isEmpty) return null;
    
    final topTheme = eventThemes.entries.reduce((a, b) => a.value > b.value ? a : b);
    final lastEvent = recentEvents.first;
    final eventTitle = (lastEvent['title'] as String? ?? 'your commitments');
    final eventDate = lastEvent['date'] != null
        ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastEvent['date'] as int))
        : 'recently';
    
    final legacyMessages = {
      'work': 'You chose purpose. Impact. Building something.',
      'family': 'You chose your people. Showing up. Being present.',
      'health': 'You chose yourself. Your body. Your care.',
      'connection': 'You chose relationship. Depth. Real contact.',
    };
    
    final legacyMessage = legacyMessages[topTheme.key] ?? 'You chose to focus. Intentionality. Presence.';
    
    return """THE LEGACY MIRROR

Looking back from 2065:

This week will be remembered as: The Week of ${topTheme.key.toUpperCase()}.

This week you scheduled time for ${topTheme.key}. That was your priority. Your choice.

Most recent commitment:
"$eventTitle" on $eventDate

The legacy:
$legacyMessage

That's what you'll remember. That's what will matter.

Your calendar shows your truth. This week, you chose ${topTheme.key}.

Make it count.""";
  }
  
  /// Analyze health themes
  String? _analyzeHealthThemes(List<Map<String, dynamic>> healthEntries, List<Map<String, dynamic>> weekEntries) {
    final now = DateTime.now();
    final recentHealth = healthEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    if (recentHealth.isEmpty) return null;
    
    final healthTypes = <String, int>{};
    for (final entry in recentHealth) {
      final type = (entry['type'] as String? ?? '').replaceAll('health_', '');
      healthTypes[type] = (healthTypes[type] ?? 0) + 1;
    }
    
    if (healthTypes.isEmpty) return null;
    
    final topHealthType = healthTypes.entries.reduce((a, b) => a.value > b.value ? a : b);
    final lastHealth = recentHealth.first;
    final healthDate = lastHealth['date'] != null
        ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastHealth['date'] as int))
        : 'recently';
    
    return """THE LEGACY MIRROR

Looking back from 2065:

This week will be remembered as: The Week of Health.

This week you focused on your ${topHealthType.key}. That was your priority.

Most recent activity:
$healthDate

The legacy:
You chose yourself. Your body. Your care.

That's what you'll remember. That's what will matter.

Your health shows your truth. This week, you chose yourself.

Make it count.""";
  }
  
  /// Analyze location themes
  String? _analyzeLocationThemes(List<Map<String, dynamic>> locationEntries, List<Map<String, dynamic>> weekEntries) {
    final now = DateTime.now();
    final recentLocations = locationEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    if (recentLocations.isEmpty) return null;
    
    final lastLocation = recentLocations.first;
    final locationDate = lastLocation['date'] != null
        ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastLocation['date'] as int))
        : 'recently';
    
    return """THE LEGACY MIRROR

Looking back from 2065:

This week will be remembered as: The Week of Presence.

This week you showed up. You went places. You were present.

Most recent location:
$locationDate

The legacy:
You chose presence. Showing up. Being there.

That's what you'll remember. That's what will matter.

Where you are shows your truth. This week, you chose presence.

Make it count.""";
  }
  
  /// Analyze photo themes
  String? _analyzePhotoThemes(List<Map<String, dynamic>> photoEntries, List<Map<String, dynamic>> weekEntries) {
    final now = DateTime.now();
    final recentPhotos = photoEntries.where((e) {
      final date = DateTime.fromMillisecondsSinceEpoch(e['date'] as int? ?? 0);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();
    
    if (recentPhotos.isEmpty) return null;
    
    final lastPhoto = recentPhotos.first;
    final photoDate = lastPhoto['date'] != null
        ? _formatDetailedDate(DateTime.fromMillisecondsSinceEpoch(lastPhoto['date'] as int))
        : 'recently';
    
    return """THE LEGACY MIRROR

Looking back from 2065:

This week will be remembered as: The Week of Documentation.

This week you captured moments. You documented your life.

Most recent capture:
$photoDate

The legacy:
You chose to remember. To capture. To document.

That's what you'll remember. That's what will matter.

What you photograph shows your truth. This week, you chose to remember.

Make it count.""";
  }

  int max(int a, int b) => a > b ? a : b;
  int min(int a, int b) => a < b ? a : b;
}

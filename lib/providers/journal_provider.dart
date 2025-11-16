import 'package:flutter_riverpod/flutter_riverpod.dart';

class JournalEntry {
  final String text;
  final DateTime timestamp;

  JournalEntry({
    required this.text,
    required this.timestamp,
  });
}

class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  JournalNotifier() : super([]);

  void addEntry(String text) {
    state = [
      ...state,
      JournalEntry(
        text: text,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

final journalProvider = StateNotifierProvider<JournalNotifier, List<JournalEntry>>(
  (ref) => JournalNotifier(),
);


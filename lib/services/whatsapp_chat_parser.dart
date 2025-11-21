import 'dart:io';
import 'dart:convert';

/// Service to parse WhatsApp chat export files (.txt format)
class WhatsAppChatParser {
  static WhatsAppChatParser? _instance;
  static WhatsAppChatParser get instance => _instance ??= WhatsAppChatParser._();
  
  WhatsAppChatParser._();

  /// Parse WhatsApp chat export file
  /// Format: [DD/MM/YYYY, HH:MM:SS AM/PM] Sender: Message
  Future<List<Map<String, dynamic>>> parseChatFile(File file) async {
    final messages = <Map<String, dynamic>>[];
    
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      // WhatsApp export format examples:
      // [12/25/23, 10:30:45 AM] John Doe: Hello
      // [12/25/23, 10:31:00 AM] You: Hi there
      // [12/25/23, 10:32:15 AM] John Doe: How are you?
      
      final messagePattern = RegExp(
        r'\[(\d{1,2}/\d{1,2}/\d{2,4}),\s*(\d{1,2}:\d{2}:\d{2}\s*(?:AM|PM))\]\s*(.+?):\s*(.+)$',
        multiLine: false,
      );
      
      String? currentDate;
      String? currentTime;
      String? currentSender;
      StringBuffer? currentMessage;
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        final match = messagePattern.firstMatch(line);
        if (match != null) {
          // Save previous message if exists
          if (currentMessage != null && currentSender != null) {
            final timestamp = _parseWhatsAppTimestamp(currentDate!, currentTime!);
            if (timestamp != null) {
              messages.add({
                'type': 'whatsapp',
                'timestamp': timestamp.toIso8601String(),
                'from': currentSender,
                'body': currentMessage.toString().trim(),
                'date': timestamp.millisecondsSinceEpoch,
              });
            }
          }
          
          // Start new message
          currentDate = match.group(1);
          currentTime = match.group(2);
          currentSender = match.group(4)?.trim();
          currentMessage = StringBuffer(match.group(5) ?? '');
        } else if (currentMessage != null) {
          // Continuation of previous message (multi-line)
          currentMessage.writeln(line.trim());
        }
      }
      
      // Save last message
      if (currentMessage != null && currentSender != null && currentDate != null && currentTime != null) {
        final timestamp = _parseWhatsAppTimestamp(currentDate, currentTime);
        if (timestamp != null) {
          messages.add({
            'type': 'whatsapp',
            'timestamp': timestamp.toIso8601String(),
            'from': currentSender,
            'body': currentMessage.toString().trim(),
            'date': timestamp.millisecondsSinceEpoch,
          });
        }
      }
      
      print('Parsed ${messages.length} WhatsApp messages from ${file.path}');
    } catch (e) {
      print('Error parsing WhatsApp chat file: $e');
    }
    
    return messages;
  }

  /// Parse WhatsApp timestamp format: "12/25/23, 10:30:45 AM"
  DateTime? _parseWhatsAppTimestamp(String dateStr, String timeStr) {
    try {
      // Parse date: "12/25/23" or "12/25/2023"
      final dateParts = dateStr.split('/');
      if (dateParts.length != 3) return null;
      
      int month = int.parse(dateParts[0]);
      int day = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);
      
      // Handle 2-digit years
      if (year < 100) {
        year += 2000; // Assume 2000s
      }
      
      // Parse time: "10:30:45 AM"
      final isPM = timeStr.toUpperCase().contains('PM');
      final timeOnly = timeStr.replaceAll(RegExp(r'[AP]M'), '').trim();
      final timeParts = timeOnly.split(':');
      if (timeParts.length < 2) return null;
      
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      int second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
      
      // Convert to 24-hour format
      if (isPM && hour != 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }
      
      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      print('Error parsing WhatsApp timestamp: $e');
      return null;
    }
  }

  /// Parse iOS Messages export (if exported as text)
  /// Format may vary, but typically: [Date] Sender: Message
  Future<List<Map<String, dynamic>>> parseiOSMessagesFile(File file) async {
    final messages = <Map<String, dynamic>>[];
    
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      // iOS Messages export format examples (varies):
      // [2023-12-25 10:30:45] John Doe: Hello
      // [2023-12-25 10:31:00] You: Hi there
      
      final messagePattern = RegExp(
        r'\[(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})\]\s*(.+?):\s*(.+)$',
        multiLine: false,
      );
      
      StringBuffer? currentMessage;
      String? currentDate;
      String? currentTime;
      String? currentSender;
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        final match = messagePattern.firstMatch(line);
        if (match != null) {
          // Save previous message
          if (currentMessage != null && currentSender != null && currentDate != null && currentTime != null) {
            final timestamp = _parseiOSTimestamp(currentDate, currentTime);
            if (timestamp != null) {
              messages.add({
                'type': 'imessage',
                'timestamp': timestamp.toIso8601String(),
                'from': currentSender,
                'body': currentMessage.toString().trim(),
                'date': timestamp.millisecondsSinceEpoch,
              });
            }
          }
          
          // Start new message
          currentDate = match.group(1);
          currentTime = match.group(2);
          currentSender = match.group(3)?.trim();
          currentMessage = StringBuffer(match.group(4) ?? '');
        } else if (currentMessage != null) {
          // Continuation line
          currentMessage.writeln(line.trim());
        }
      }
      
      // Save last message
      if (currentMessage != null && currentSender != null && currentDate != null && currentTime != null) {
        final timestamp = _parseiOSTimestamp(currentDate, currentTime);
        if (timestamp != null) {
          messages.add({
            'type': 'imessage',
            'timestamp': timestamp.toIso8601String(),
            'from': currentSender,
            'body': currentMessage.toString().trim(),
            'date': timestamp.millisecondsSinceEpoch,
          });
        }
      }
      
      print('Parsed ${messages.length} iOS Messages from ${file.path}');
    } catch (e) {
      print('Error parsing iOS Messages file: $e');
    }
    
    return messages;
  }

  DateTime? _parseiOSTimestamp(String dateStr, String timeStr) {
    try {
      return DateTime.parse('$dateStr $timeStr');
    } catch (e) {
      print('Error parsing iOS timestamp: $e');
      return null;
    }
  }
}


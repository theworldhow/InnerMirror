import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../widgets/regret_simulator_overlay.dart';
import 'regret_simulator_service.dart';

class ShareExtensionService {
  static ShareExtensionService? _instance;
  static ShareExtensionService get instance => _instance ??= ShareExtensionService._();
  
  ShareExtensionService._();
  
  StreamSubscription? _intentDataStreamSubscription;
  StreamSubscription? _textStreamSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void initialize() {
    // Listen for shared text
    // Note: receive_sharing_intent API varies by version
    // This functionality may need to be implemented based on the specific package version
    // For now, this is a placeholder that will need API-specific implementation
    try {
      // The API structure may differ - this needs to be adjusted based on the actual package version
      // Check receive_sharing_intent package documentation for the correct API
      print("Share extension service initialized (implementation may need adjustment)");
    } catch (e) {
      print("Share extension initialization error: $e");
    }
  }

  void _showRegretSimulator(String text) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: true,
      builder: (context) => RegretSimulatorOverlay(
        text: text,
        onEdit: (editedText) {
          // Copy edited text to clipboard
          // In production, would replace text in source app
          Navigator.of(context).pop();
        },
        onSend: () {
          // User chose to send as is
          Navigator.of(context).pop();
        },
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _textStreamSubscription?.cancel();
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/future_you_voice_service.dart';
import 'future_you_voice_screen.dart';

class FutureYouMessagesScreen extends StatefulWidget {
  final VoidCallback? onBack;
  
  const FutureYouMessagesScreen({super.key, this.onBack});

  @override
  State<FutureYouMessagesScreen> createState() => _FutureYouMessagesScreenState();
}

class _FutureYouMessagesScreenState extends State<FutureYouMessagesScreen> {
  List<FutureYouVoiceMessage> _messages = [];
  bool _isLoading = true;
  bool _isFirstTime = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _loadMessages();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final firstTimeIngestionComplete = prefs.getBool('first_time_ingestion_complete') ?? false;
    // Show first-time message if ingestion is complete (regardless of whether messages exist yet)
    // This flag will remain true until user dismisses it or we set a flag after first week
    setState(() {
      _isFirstTime = firstTimeIngestionComplete;
    });
  }

  Future<void> _loadMessages() async {
    final service = FutureYouVoiceService.instance;
    final messages = await service.getMessages();
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    
    // Re-check first-time status after loading
    await _checkFirstTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to home (tab 0)
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              // Fallback: try to pop if we're in a route
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            }
          },
        ),
        title: const Text(
          'Future You 2035',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No messages yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      if (_isFirstTime) ...[
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Check back every Sunday at 8 AM for your Weekly Updates.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                              fontFamily: '.SF Pro Text',
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 24),
                        Text(
                          'Check back Sunday at 8 AM.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return Card(
                            color: Colors.grey.shade900,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                message.text.split('\n').first,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: '.SF Pro Text',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${message.createdAt.year}-${message.createdAt.month.toString().padLeft(2, '0')}-${message.createdAt.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                              trailing: const Icon(Icons.play_circle, color: Colors.white),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => FutureYouVoiceScreen(message: message),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    if (_isFirstTime)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Check back every Sunday at 8 AM for your Weekly Updates.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontFamily: '.SF Pro Text',
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}


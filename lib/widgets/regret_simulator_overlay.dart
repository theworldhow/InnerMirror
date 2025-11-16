import 'package:flutter/material.dart';
import '../services/regret_simulator_service.dart';

class RegretSimulatorOverlay extends StatefulWidget {
  final String text;
  final Function(String)? onEdit;
  final VoidCallback? onSend;
  final VoidCallback? onDismiss;

  const RegretSimulatorOverlay({
    super.key,
    required this.text,
    this.onEdit,
    this.onSend,
    this.onDismiss,
  });

  @override
  State<RegretSimulatorOverlay> createState() => _RegretSimulatorOverlayState();
}

class _RegretSimulatorOverlayState extends State<RegretSimulatorOverlay> {
  RegretAnalysis? _analysis;
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    final service = RegretSimulatorService.instance;
    final analysis = await service.analyzeText(widget.text);
    
    if (mounted) {
      setState(() {
        _analysis = analysis;
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Regret Simulator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isAnalyzing)
                const CircularProgressIndicator(color: Colors.white)
              else if (_analysis != null) ...[
                // Regret chance
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _analysis!.regretChance > 50 
                        ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_analysis!.regretChance}% chance you\'ll cringe in 72 hours',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _analysis!.reason,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 14,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Suggested edit
                if (_analysis!.suggestedEdit != null) ...[
                  const Text(
                    'Suggested edit:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _analysis!.suggestedEdit!,
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      widget.onEdit?.call(_analysis!.suggestedEdit!);
                      widget.onDismiss?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Use This Edit'),
                  ),
                  const SizedBox(height: 8),
                ],
                // Send as is button
                OutlinedButton(
                  onPressed: () {
                    widget.onSend?.call();
                    widget.onDismiss?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Send As Is'),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}


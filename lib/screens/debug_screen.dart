import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/memory_provider.dart';
import '../services/life_log_service.dart';
import '../services/data_ingestion_service.dart';
import '../services/mirror_generation_service.dart';
import '../services/legacy_export_service.dart';
import '../services/revenue_cat_service.dart';
import '../utils/screenshot_mode.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  bool _isIngesting = false;
  bool _isRegenerating = false;
  bool _isExporting = false;

  Future<void> _forceIngest() async {
    setState(() {
      _isIngesting = true;
    });

    try {
      final ingestion = DataIngestionService.instance;
      await ingestion.ingestAll();
      
      // Refresh providers
      ref.invalidate(totalMomentsProvider);
      ref.invalidate(lastIngestionTimeProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingestion complete'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isIngesting = false;
        });
      }
    }
  }

  Future<void> _regenerateMirrors() async {
    setState(() {
      _isRegenerating = true;
    });

    try {
      final mirrorGen = MirrorGenerationService.instance;
      await mirrorGen.generateAllMirrors();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mirrors regenerated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });
      }
    }
  }

  Future<void> _exportLegacy() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Check if user has purchased legacy
      final customerInfo = await RevenueCatService.getCustomerInfo();
      final hasLegacy = customerInfo?.entitlements.active.containsKey('legacy') ?? false;

      if (!hasLegacy) {
        // Show purchase screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Legacy Export requires \$99 one-time purchase'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final exportService = LegacyExportService.instance;
      final exportFile = await exportService.exportSoulModel();
      
      // Share the file
      await Share.shareXFiles(
        [XFile(exportFile.path)],
        text: 'My InnerMirror Soul Model Export',
        subject: 'InnerMirror Legacy Export',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export complete'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<String> _getLifeLogPath() async {
    try {
      final file = await LifeLogService.instance.getLifeLogFile();
      final dir = await getApplicationDocumentsDirectory();
      final relativePath = file.path.replaceFirst(dir.path, '');
      return '${dir.path}${relativePath}';
    } catch (e) {
      return 'Error getting path: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastIngestionAsync = ref.watch(lastIngestionTimeProvider);
    final totalMomentsAsync = ref.watch(totalMomentsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Debug',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last ingestion time
            Text(
              'Last Ingestion',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
                fontFamily: '.SF Pro Text',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            lastIngestionAsync.when(
              data: (time) => Text(
                time != null
                    ? '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                    : 'Never',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading'),
            ),
            const SizedBox(height: 32),
            // Total moments
            Text(
              'Total Moments',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
                fontFamily: '.SF Pro Text',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            totalMomentsAsync.when(
              data: (count) => Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading'),
            ),
            const SizedBox(height: 32),
            // Force ingest button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isIngesting ? null : _forceIngest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isIngesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Force Ingest Now',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Regenerate mirrors button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRegenerating ? null : _regenerateMirrors,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isRegenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Regenerate Mirrors Now',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Screenshot mode toggle
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final wasEnabled = ScreenshotMode.enabled;
                  if (wasEnabled) {
                    ScreenshotMode.disable();
                  } else {
                    ScreenshotMode.enable();
                  }
                  setState(() {});
                  
                  // Show message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ScreenshotMode.enabled 
                          ? 'Screenshot Mode: ON\nGo back and swipe between cards to see sample content'
                          : 'Screenshot Mode: OFF\nGo back to see normal content',
                      ),
                      duration: const Duration(seconds: 3),
                      backgroundColor: ScreenshotMode.enabled ? Colors.orange : Colors.grey.shade800,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScreenshotMode.enabled ? Colors.orange : Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  ScreenshotMode.enabled ? 'Screenshot Mode: ON' : 'Screenshot Mode: OFF',
                  style: const TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Legacy Export button (behind paywall)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isExporting ? null : _exportLegacy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Legacy Export (\$99)',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            // File path display
            FutureBuilder<String>(
              future: _getLifeLogPath(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Card(
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'File Location:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            snapshot.data!,
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'To view: Run ./scripts/view_life_log.sh in terminal',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 32),
            // Sample entries
            Text(
              'Last 10 Entries',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade400,
                fontFamily: '.SF Pro Text',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: LifeLogService.instance.getRecentEntries(count: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red.shade300),
                  );
                }
                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return Text(
                    'No entries yet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontFamily: '.SF Pro Text',
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry['type']} - ${entry['timestamp']}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            const JsonEncoder.withIndent('  ').convert(entry),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade300,
                              fontFamily: '.SF Pro Mono',
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


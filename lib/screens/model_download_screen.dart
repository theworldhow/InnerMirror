import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/soul_model_provider.dart';
import '../services/model_download_service.dart';
import '../services/device_info_service.dart';

class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  ConsumerState<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  double _progress = 0.0;
  bool _downloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      setState(() {
        _downloading = true;
        _error = null;
      });

      final deviceInfo = ref.read(deviceInfoServiceProvider);
      final use8B = await deviceInfo.shouldUse8BModel();
      final downloadService = ref.read(modelDownloadServiceProvider);

      // Check if model already exists
      if (await downloadService.modelExists(use8B: use8B)) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        return;
      }

      await downloadService.downloadModel(
        use8B: use8B,
        onProgress: (bytesDownloaded, totalBytes) {
          if (mounted) {
            setState(() {
              _progress = totalBytes > 0 
                  ? bytesDownloaded / totalBytes 
                  : 0.0;
            });
          }
        },
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_downloading) ...[
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Waking your Soul Model…',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    fontFamily: '.SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'this takes 3–7 minutes the first time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey.shade400,
                    fontFamily: '.SF Pro Text',
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_progress > 0) ...[
                  const SizedBox(height: 24),
                  Text(
                    '${(_progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey.shade500,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ] else if (_error != null) ...[
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade300,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'Download failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey.shade400,
                    fontFamily: '.SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: _startDownload,
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


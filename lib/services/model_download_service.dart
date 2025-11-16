import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ModelDownloadService {
  // Using Hugging Face direct download URLs
  static const String model8BUrl = 'https://huggingface.co/second-state/Llama-3.2-8B-Instruct-GGUF/resolve/main/Llama-3.2-8B-Instruct-Q4_K_M.gguf';
  static const String model3BUrl = 'https://huggingface.co/second-state/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q5_K_M.gguf';
  
  static const String model8BName = 'Llama-3.2-8B-Instruct-Q4_K_M.gguf';
  static const String model3BName = 'Llama-3.2-3B-Instruct-Q5_K_M.gguf';

  Future<File> getModelFile({required bool use8B}) async {
    final directory = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${directory.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    final modelName = use8B ? model8BName : model3BName;
    return File('${modelsDir.path}/$modelName');
  }

  Future<bool> modelExists({required bool use8B}) async {
    final file = await getModelFile(use8B: use8B);
    return await file.exists();
  }

  Future<void> downloadModel({
    required bool use8B,
    required Function(int bytesDownloaded, int totalBytes) onProgress,
  }) async {
    final file = await getModelFile(use8B: use8B);
    
    if (await file.exists()) {
      return;
    }

    final url = use8B ? model8BUrl : model3BUrl;
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception('Failed to download model: ${response.statusCode}');
    }

    final contentLength = response.contentLength ?? 0;
    int bytesDownloaded = 0;
    int lastFlushSize = 0;
    const flushInterval = 1024 * 1024; // Flush every 1MB

    // Stream directly to file to avoid loading entire file into memory
    final sink = file.openWrite();
    
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        bytesDownloaded += chunk.length;
        onProgress(bytesDownloaded, contentLength);
        
        // Force periodic flushes to disk to free memory
        if (bytesDownloaded - lastFlushSize >= flushInterval) {
          await sink.flush();
          lastFlushSize = bytesDownloaded;
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  Future<int> getModelSize({required bool use8B}) async {
    final file = await getModelFile(use8B: use8B);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
}


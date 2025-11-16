import 'dart:io';
import 'dart:async';
import 'dart:convert';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Disabled - avoiding potential native crashes
// import 'package:sqflite/sqflite.dart'; // Disabled - using file storage instead to avoid native crashes
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class Secret {
  final int? id;
  final String content;
  final DateTime createdAt;
  final bool isVoice;

  Secret({
    this.id,
    required this.content,
    required this.createdAt,
    this.isVoice = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'content': content,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'isVoice': isVoice ? 1 : 0,
  };

  factory Secret.fromMap(Map<String, dynamic> map) => Secret(
    id: map['id'],
    content: map['content'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    isVoice: map['isVoice'] == 1,
  );
}

class SecretsVaultService {
  static SecretsVaultService? _instance;
  static SecretsVaultService get instance => _instance ??= SecretsVaultService._();
  
  SecretsVaultService._();
  
  // Disabled flutter_secure_storage to avoid potential native crashes
  // Using file storage only - no encryption needed for now
  // static const _storage = FlutterSecureStorage();
  // Database? _db; // Disabled - using file storage instead
  bool _isUnlocked = false;
  // bool _isInitializing = false; // Disabled
  // Future<Database>? _initFuture; // Disabled
  bool _useFileStorage = true; // Always use file storage to avoid sqflite crashes on iOS

  // Database getter disabled - always use file storage
  // Future<Database> get database async {
  //   throw Exception('Database disabled - using file storage');
  // }

  // Encryption key generation disabled - not needed for file storage
  // Future<String> _getEncryptionKey() async {
  //   String? key = await _storage.read(key: 'vault_encryption_key');
  //   if (key == null) {
  //     // Generate a secure key
  //     key = DateTime.now().millisecondsSinceEpoch.toString() + 
  //           (await getApplicationDocumentsDirectory()).path;
  //     await _storage.write(key: 'vault_encryption_key', value: key);
  //   }
  //   return key;
  // }

  Future<bool> unlock() async {
    // Using file storage by default - no database initialization needed
    // This avoids native crashes from sqflite on iOS
    _isUnlocked = true;
    return true;
  }

  void lock() {
    _isUnlocked = false;
  }

  bool get isUnlocked => _isUnlocked;

  Future<void> addSecret(String content, {bool isVoice = false}) async {
    if (!_isUnlocked) throw Exception('Vault is locked');
    
    // Always use file storage - database is disabled
    await _addSecretToFile(content, isVoice: isVoice);
  }

  Future<List<Secret>> getAllSecrets() async {
    if (!_isUnlocked) throw Exception('Vault is locked');
    
    // Always use file storage - database is disabled
    try {
      return await _getSecretsFromFile();
    } catch (e) {
      print('Error getting secrets from file: $e');
      return []; // Return empty list instead of crashing
    }
  }
  
  Future<File> _getSecretsFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final secretsDir = Directory('${dir.path}/innermirror/secrets');
      if (!await secretsDir.exists()) {
        await secretsDir.create(recursive: true);
      }
      return File('${secretsDir.path}/secrets.json');
    } catch (e) {
      print('Error getting secrets file path: $e');
      // Fallback to documents directory directly
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/secrets.json');
    }
  }
  
  Future<void> _addSecretToFile(String content, {bool isVoice = false}) async {
    try {
      final file = await _getSecretsFile();
      final secrets = await _getSecretsFromFile();
      secrets.add(Secret(
        content: content,
        createdAt: DateTime.now(),
        isVoice: isVoice,
      ));
      final json = jsonEncode(secrets.map((s) => s.toMap()).toList());
      await file.writeAsString(json);
    } catch (e) {
      print('Error adding secret to file: $e');
      rethrow;
    }
  }
  
  Future<List<Secret>> _getSecretsFromFile() async {
    try {
      final file = await _getSecretsFile();
      if (!await file.exists()) {
        return [];
      }
      try {
        final json = await file.readAsString();
        final List<dynamic> data = jsonDecode(json);
        return data.map((map) => Secret.fromMap(Map<String, dynamic>.from(map))).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
        print('Error reading secrets file: $e');
        return [];
      }
    } catch (e) {
      print('Error getting secrets file: $e');
      return [];
    }
  }

  Future<void> burnAllSecrets() async {
    if (!_isUnlocked) throw Exception('Vault is locked');
    
    try {
      // Always use file storage - database is disabled
      final file = await _getSecretsFile();
      if (await file.exists()) {
        await file.delete();
      }
      
      // Encryption key deletion disabled - not using secure storage
      // try {
      //   await _storage.delete(key: 'vault_encryption_key');
      // } catch (e) {
      //   print('Error deleting encryption key: $e');
      //   // Continue even if key deletion fails
      // }
      
      _isUnlocked = false;
    } catch (e) {
      print('Error burning secrets: $e');
      // Don't rethrow - try to continue
      _isUnlocked = false;
    }
  }

  Future<bool> isBurnDay() async {
    final now = DateTime.now();
    return now.month == 12 && now.day == 31;
  }
}


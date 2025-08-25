import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;

typedef ProgressCallback = void Function(int downloaded, int total, double progress);

class ModelDownloader {
  static const String MODEL_URL = "https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task";
  static const String MODEL_FILENAME = "gemma3-1b-it-int4.task";
  static const String HF_TOKEN_KEY = "huggingface_token";

  static const int MIN_MODEL_SIZE = 500000000;

  // Token management
  static Future<void> saveHuggingFaceToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(HF_TOKEN_KEY, token);
  }

  static Future<String?> getHuggingFaceToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(HF_TOKEN_KEY);
  }

  static Future<bool> hasValidToken() async {
    final tok = await getHuggingFaceToken();
    return tok != null && tok.startsWith('hf_');
  }

  // Paths
  static Future<String> getModelFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/models/$MODEL_FILENAME';
  }
  static Future<String> getModelDirectory() async {
    final filePath = await getModelFilePath();
    return File(filePath).parent.path;
  }

  // Validation
  static Future<bool> isModelDownloaded() => _statelessValidate();
  static Future<bool> deleteModel() async {
    try {
      final path = await getModelFilePath();
      final f = File(path);
      if (await f.exists()) await f.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<int> getModelFileSize() async {
    try {
      final f = File(await getModelFilePath());
      if (await f.exists()) return await f.length();
    } catch (_) {}
    return 0;
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelPath = await getModelFilePath();
      final exists = await File(modelPath).exists();
      final size = exists ? await File(modelPath).length() : 0;
      return {
        'app_documents_path': dir.path,
        'model_directory': await getModelDirectory(),
        'model_file_path': modelPath,
        'model_exists': exists,
        'model_size': formatBytes(size),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Legacy downloadModel API forwards to file-picker approach
  static Future<bool> downloadModel({
    required ProgressCallback onProgress,
    required VoidCallback onComplete,
    required Function(String) onError,
    String? huggingFaceToken,
  }) {
    // ignore progress parameters; file-picker is manual
    return selectAndLoadModel(onComplete: onComplete, onError: onError);
  }

  // File-picker method
  static Future<bool> selectAndLoadModel({
    required VoidCallback onComplete,
    required Function(String) onError,
  }) async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['task'],
        dialogTitle: 'Select Gemma Model File',
      );
      if (res == null || res.files.single.path == null) {
        onError('No file selected');
        return false;
      }
      final sel = File(res.files.single.path!);
      if (!await sel.exists()) {
        onError('Selected file does not exist');
        return false;
      }
      final size = await sel.length();
      if (size < MIN_MODEL_SIZE) {
        onError('Selected file too small (${formatBytes(size)})');
        return false;
      }
      if (!await _validateModel(sel)) {
        onError('Selected file is not a valid .task model');
        return false;
      }
      final dest = File(await getModelFilePath());
      await dest.parent.create(recursive: true);
      await sel.copy(dest.path);
      if (await isModelDownloaded()) {
        onComplete();
        return true;
      } else {
        onError('Failed to validate copied model');
        return false;
      }
    } catch (e) {
      onError('File selection error: $e');
      return false;
    }
  }

  // Shared validation logic
  static Future<bool> _statelessValidate() async {
    try {
      final path = await getModelFilePath();
      final file = File(path);
      if (!await file.exists()) return false;
      final size = await file.length();
      if (size < MIN_MODEL_SIZE) return false;
      return _validateModel(file);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _validateModel(File file) async {
    try {
      final header = await file.openRead(0, 1024).first;
      if (header.every((b) => b == 0)) return false;
      final sig = header.sublist(0, 4);
      final zipSig = [0x50, 0x4B, 0x03, 0x04];
      if (ListEquality().equals(sig, zipSig)) return true;
      if (sig[0] == 0x1C && sig[1] == 0x00) return true;
      if (sig[0] == 0x54 && sig[1] == 0x46 && sig[2] == 0x4C) return true;
      return false;
    } catch (_) {
      return false;
    }
  }
}

// For ListEquality in header comparison


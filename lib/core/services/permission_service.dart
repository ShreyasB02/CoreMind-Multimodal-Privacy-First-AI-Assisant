import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class PermissionService {
  // static const _platform = MethodChannel('com.coremind.assistant/permissions');

  static Future<bool> requestVoicePermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.speech,
      Permission.storage,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool allGranted = statuses.values.every(
            (status) => status == PermissionStatus.granted
    );

    if (!allGranted) {
      await _showPermissionDialog();
    }

    return allGranted;
  }

  static Future<void> _showPermissionDialog() async {
    // Guide user to settings if needed
    await openAppSettings();
  }

}

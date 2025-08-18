import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestVoicePermissions() async {
    // Check current status first
    var status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isPermanentlyDenied) {
      // Guide user to settings
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }
}


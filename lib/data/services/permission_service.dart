import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request All Files Access (Android 11+)
  static Future<bool> requestAllFilesPermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    await openAppSettings();

    return await Permission.manageExternalStorage.isGranted;
  }
}

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageHelper {
  static final StorageHelper _instance = StorageHelper._internal();

  factory StorageHelper() {
    return _instance;
  }

  StorageHelper._internal();

  /// Request storage permissions
  Future<bool> requestPermissions() async {
    bool hasPermission = true;

    if (Platform.isAndroid) {
      // Request storage permission
      PermissionStatus status = await Permission.storage.request();
      print('Storage permission status: $status');

      if (status.isDenied) {
        hasPermission = false;
      }

      // For Android 11 (API level 30) and above
      if (await Permission.manageExternalStorage.isRestricted) {
        PermissionStatus status =
            await Permission.manageExternalStorage.request();
        print('Manage external storage permission status: $status');

        if (status.isDenied) {
          hasPermission = false;
        }
      }
    }

    return hasPermission;
  }

  /// Get the custom data directory path
  Future<String> getCustomDataPath() async {
    // Define custom path
    String customPath;

    if (Platform.isWindows) {
      // Custom path for Windows
      customPath = 'C:\\MedDexData';
    } else if (Platform.isAndroid) {
      // Use external storage for Android
      Directory? externalDir = await getExternalStorageDirectory();
      customPath = join(externalDir?.path ?? '', 'MedDexData');
    } else {
      // Default path for other platforms
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      customPath = join(documentsDirectory.path, 'MedDexData');
    }

    // Create the directory if it doesn't exist
    Directory customDir = Directory(customPath);
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }

    return customPath;
  }

  /// Get the full database file path
  Future<String> getDatabasePath() async {
    String customPath = await getCustomDataPath();
    return join(customPath, 'meddex.db');
  }

  /// Export data to another location
  Future<bool> exportDatabase(String destinationPath) async {
    try {
      String dbPath = await getDatabasePath();
      File dbFile = File(dbPath);

      if (await dbFile.exists()) {
        await dbFile.copy(destinationPath);
        return true;
      }
      return false;
    } catch (e) {
      print('Error exporting database: $e');
      return false;
    }
  }

  /// Import data from another location
  Future<bool> importDatabase(String sourcePath) async {
    try {
      File sourceFile = File(sourcePath);

      if (await sourceFile.exists()) {
        String dbPath = await getDatabasePath();
        await sourceFile.copy(dbPath);
        return true;
      }
      return false;
    } catch (e) {
      print('Error importing database: $e');
      return false;
    }
  }
}

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as pp;

class StorageHelper {
  /// Gets the user-accessible Downloads directory across Android, iOS, and Desktop platforms.
  static Future<Directory> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // 1. Direct check for standard public Android Downloads folder
      final primaryDownload = Directory('/storage/emulated/0/Download');
      if (await primaryDownload.exists()) {
        return primaryDownload;
      }
      
      final altDownload = Directory('/storage/emulated/0/Downloads');
      if (await altDownload.exists()) {
        return altDownload;
      }

      // 2. Try creating /storage/emulated/0/Download
      try {
        if (!await primaryDownload.exists()) {
          await primaryDownload.create(recursive: true);
        }
        return primaryDownload;
      } catch (_) {}

      // 3. Fallback to external downloads directory
      try {
        final extDirs = await pp.getExternalStorageDirectories(type: pp.StorageDirectory.downloads);
        if (extDirs != null && extDirs.isNotEmpty) {
          return extDirs.first;
        }
      } catch (_) {}

      // 4. Fallback to external storage root
      try {
        final extDir = await pp.getExternalStorageDirectory();
        if (extDir != null) {
          final downloadDir = Directory(p.join(extDir.path, 'Download'));
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          return downloadDir;
        }
      } catch (_) {}
    } else if (Platform.isWindows || Platform.isLinux) {
      try {
        final dir = await pp.getDownloadsDirectory();
        if (dir != null) return dir;
      } catch (_) {}
    }

    // Default fallback to app documents directory
    final appDocDir = await pp.getApplicationDocumentsDirectory();
    final fallbackDir = Directory(p.join(appDocDir.path, 'Downloads'));
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }
    return fallbackDir;
  }

  /// Verifies that a file exists and has non-zero size
  static Future<bool> verifyFileExistsAndNonEmpty(File file) async {
    if (!await file.exists()) return false;
    final length = await file.length();
    return length > 0;
  }

  /// Formats byte size to human readable string (e.g., 24.5 KB)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

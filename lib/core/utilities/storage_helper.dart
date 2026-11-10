import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as pp;

import '../../features/backup/presentation/screens/export_history_screen.dart';

class StorageHelper {
  static const MethodChannel _platformChannel =
      MethodChannel('com.kals.kals_money_manager/widget_channel');

  /// Optional custom user-selected export destination directory.
  static String? customExportDirectory;

  /// Gets the user-accessible local storage directory across Android, iOS, and Desktop platforms.
  /// On Android, always points to standard public Downloads (/storage/emulated/0/Download/).
  static Future<Directory> getDownloadsDirectory() async {
    // 0. Custom user-selected directory (if configured, existing, and writable)
    if (customExportDirectory != null && customExportDirectory!.trim().isNotEmpty) {
      try {
        final customDir = Directory(customExportDirectory!);
        if (await customDir.exists() && await _isWritable(customDir)) {
          return customDir;
        }
      } catch (_) {}
    }

    if (Platform.isAndroid) {
      // 1. Standard Public Downloads directory
      final primaryDownload = Directory('/storage/emulated/0/Download');
      if (await primaryDownload.exists()) {
        return primaryDownload;
      }
      final altDownload = Directory('/storage/emulated/0/Downloads');
      if (await altDownload.exists()) {
        return altDownload;
      }
      return primaryDownload;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        final dir = await pp.getDownloadsDirectory();
        if (dir != null && await _isWritable(dir)) return dir;
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

  /// Saves file bytes directly into the public Downloads collection (/storage/emulated/0/Download/ on Android).
  /// Uses MediaStore Downloads on Android 10+ (API 29+) without requiring broad storage permissions.
  /// Handles duplicate filenames safely (e.g., appends (1), (2)).
  /// Verifies that the file exists and is readable before returning.
  static Future<File> saveToPublicDownloads({
    required List<int> bytes,
    required String fileName,
    String? mimeType,
  }) async {
    // 0. User custom directory (if set and writable)
    if (customExportDirectory != null && customExportDirectory!.trim().isNotEmpty) {
      final customDir = Directory(customExportDirectory!);
      if (await customDir.exists() && await _isWritable(customDir)) {
        return _writeUniqueFile(customDir, fileName, bytes);
      }
    }

    if (Platform.isAndroid) {
      try {
        final resolvedMime = mimeType ?? inferMimeType(fileName);
        final result = await _platformChannel.invokeMapMethod<String, dynamic>(
          'saveFileToPublicDownloads',
          {
            'bytes': Uint8List.fromList(bytes),
            'fileName': fileName,
            'mimeType': resolvedMime,
          },
        );

        if (result != null && result['filePath'] != null) {
          final filePath = result['filePath'] as String;
          final file = File(filePath);
          final isValid = await verifyFileExistsAndNonEmpty(file);
          if (isValid) {
            return file;
          }
        }
      } catch (_) {
        // Fall back below if platform channel fails
      }
    }

    // Fallback for Desktop (Windows/macOS/Linux) or Android fallback
    final targetDir = await getDownloadsDirectory();
    return _writeUniqueFile(targetDir, fileName, bytes);
  }

  /// Infers standard MIME type from filename extension
  static String inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    } else if (lower.endsWith('.csv')) {
      return 'text/csv';
    } else if (lower.endsWith('.json')) {
      return 'application/json';
    } else if (lower.endsWith('.mmb')) {
      return 'application/octet-stream';
    }
    return 'application/octet-stream';
  }

  /// Writes file bytes resolving duplicate names safely (appends (1), (2), etc.)
  static Future<File> _writeUniqueFile(
    Directory dir,
    String originalName,
    List<int> bytes,
  ) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final ext = p.extension(originalName);
    final base = p.basenameWithoutExtension(originalName);

    var candidateName = originalName;
    var counter = 1;
    var candidateFile = File(p.join(dir.path, candidateName));

    while (await candidateFile.exists()) {
      candidateName = '$base ($counter)$ext';
      candidateFile = File(p.join(dir.path, candidateName));
      counter++;
    }

    await candidateFile.writeAsBytes(bytes, flush: true);
    final isValid = await verifyFileExistsAndNonEmpty(candidateFile);
    if (!isValid) {
      throw Exception('Failed to verify exported file at ${candidateFile.path}');
    }
    return candidateFile;
  }

  /// Tests whether the directory is actually writable by the current process
  static Future<bool> _isWritable(Directory dir) async {
    try {
      final probe = File(p.join(dir.path, '.probe_${DateTime.now().microsecondsSinceEpoch}'));
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
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

  /// Opens the folder in the native platform file viewer (e.g., Android Downloads/Files app, Explorer, Finder)
  static Future<bool> openFolder(Directory dir) async {
    try {
      if (Platform.isAndroid) {
        final result = await _platformChannel.invokeMethod<bool>('openFolder', {'path': dir.path});
        if (result == true) return true;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final result = await OpenFilex.open(dir.path);
        if (result.type == ResultType.done) return true;
      }
    } catch (_) {}
    return false;
  }

  /// Tries to open the native platform folder; if unsupported or failed, navigates to ExportHistoryScreen as a compatible fallback.
  static Future<void> openExportFolder(BuildContext context, {Directory? directory, File? file}) async {
    final targetDir = directory ?? file?.parent ?? await getDownloadsDirectory();
    final openedNative = await openFolder(targetDir);

    if (!openedNative && context.mounted) {
      // Graceful fallback to ExportHistoryScreen listing previously exported files
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExportHistoryScreen(
            highlightFilePath: file?.path,
          ),
        ),
      );
    }
  }

  /// Returns all exported Excel (.xlsx) and Backup (.mmb) files across relevant device directories
  static Future<List<File>> getExportedFiles() async {
    final List<File> files = [];
    final Set<String> seenPaths = {};

    // 1. Android MediaStore public Downloads query
    if (Platform.isAndroid) {
      try {
        final List<dynamic>? nativeFiles =
            await _platformChannel.invokeListMethod<dynamic>('getPublicExportedFiles');
        if (nativeFiles != null) {
          for (final item in nativeFiles) {
            if (item is Map) {
              final path = item['path'] as String?;
              if (path != null && !seenPaths.contains(path)) {
                final file = File(path);
                if (file.existsSync() && file.lengthSync() > 0) {
                  seenPaths.add(path);
                  files.add(file);
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    final List<Directory> candidateDirs = [];

    // Custom directory if set
    if (customExportDirectory != null && customExportDirectory!.trim().isNotEmpty) {
      candidateDirs.add(Directory(customExportDirectory!));
    }

    try {
      final downloadsDir = await getDownloadsDirectory();
      candidateDirs.add(downloadsDir);
    } catch (_) {}

    try {
      final appDocDir = await pp.getApplicationDocumentsDirectory();
      candidateDirs.add(Directory(p.join(appDocDir.path, 'Downloads')));
      candidateDirs.add(appDocDir);
    } catch (_) {}

    if (Platform.isAndroid) {
      try {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) candidateDirs.add(publicDownload);
      } catch (_) {}
      try {
        final publicDownloads = Directory('/storage/emulated/0/Downloads');
        if (await publicDownloads.exists()) candidateDirs.add(publicDownloads);
      } catch (_) {}
    }

    for (final dir in candidateDirs) {
      try {
        if (!await dir.exists()) continue;
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            final ext = p.extension(entity.path).toLowerCase();
            if (ext == '.xlsx' || ext == '.mmb') {
              if (!seenPaths.contains(entity.path) && entity.existsSync() && entity.lengthSync() > 0) {
                seenPaths.add(entity.path);
                files.add(entity);
              }
            }
          }
        }
      } catch (_) {}
    }

    // Sort descending by last modified
    files.sort((a, b) {
      try {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      } catch (_) {
        return 0;
      }
    });

    return files;
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AttachmentService {
  static final ImagePicker _picker = ImagePicker();

  /// Gets the local app documents attachments directory
  static Future<Directory> getAttachmentsDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final attDir = Directory(p.join(docsDir.path, 'attachments'));
    if (!await attDir.exists()) {
      await attDir.create(recursive: true);
    }
    return attDir;
  }

  /// Resolves an attachment file from a relative filename or full path
  static Future<File?> resolveFile(String? pathOrName) async {
    if (pathOrName == null || pathOrName.trim().isEmpty) return null;
    final trimmed = pathOrName.trim();

    // Check direct file if absolute
    final directFile = File(trimmed);
    if (await directFile.exists()) {
      return directFile;
    }

    // Resolve in attachments directory
    final attDir = await getAttachmentsDirectory();
    final resolvedFile = File(p.join(attDir.path, p.basename(trimmed)));
    if (await resolvedFile.exists()) {
      return resolvedFile;
    }

    return null;
  }

  /// Picks an image from Camera or Gallery and saves it locally
  static Future<String?> pickAndSaveImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final attDir = await getAttachmentsDirectory();
      final ext = p.extension(pickedFile.path).isNotEmpty
          ? p.extension(pickedFile.path)
          : '.jpg';
      final fileName = 'att_${DateTime.now().millisecondsSinceEpoch}$ext';
      final targetPath = p.join(attDir.path, fileName);

      final savedFile = await File(pickedFile.path).copy(targetPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Deletes an attachment file safely
  static Future<void> deleteAttachment(String? pathOrName) async {
    if (pathOrName == null || pathOrName.isEmpty) return;
    try {
      final file = await resolveFile(pathOrName);
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting attachment: $e');
    }
  }

  /// Reads all attachment files and encodes them to a Map of fileName to base64String for backup
  static Future<Map<String, String>> exportAttachmentsForBackup() async {
    final result = <String, String>{};
    try {
      final attDir = await getAttachmentsDirectory();
      if (!await attDir.exists()) return result;

      final files = attDir.listSync().whereType<File>();
      for (final file in files) {
        final name = p.basename(file.path);
        final bytes = await file.readAsBytes();
        result[name] = base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Error exporting attachments for backup: $e');
    }
    return result;
  }

  /// Restores attachments from a Map of fileName to base64String
  static Future<void> restoreAttachmentsFromBackup(Map<String, dynamic> attachments) async {
    try {
      final attDir = await getAttachmentsDirectory();
      for (final entry in attachments.entries) {
        final fileName = entry.key;
        final b64 = entry.value as String?;
        if (b64 != null && b64.isNotEmpty) {
          final bytes = base64Decode(b64);
          final file = File(p.join(attDir.path, fileName));
          await file.writeAsBytes(bytes, flush: true);
        }
      }
    } catch (e) {
      debugPrint('Error restoring attachments: $e');
    }
  }
}

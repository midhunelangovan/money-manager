import 'dart:io';
import 'package:flutter/material.dart';
import '../services/attachment_service.dart';
import '../theme/app_colors.dart';

class PhotoPreviewDialog extends StatelessWidget {
  final String imagePath;
  final String? title;

  const PhotoPreviewDialog({
    super.key,
    required this.imagePath,
    this.title,
  });

  static Future<void> show(
    BuildContext context, {
    required String imagePath,
    String? title,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => PhotoPreviewDialog(
        imagePath: imagePath,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Bar with Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title ?? 'Receipt / Photo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Image View
          Flexible(
            child: FutureBuilder<File?>(
              future: AttachmentService.resolveFile(imagePath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                final file = snapshot.data;
                if (file == null || !file.existsSync()) {
                  return Container(
                    height: 200,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded, size: 48, color: Colors.white54),
                          SizedBox(height: 12),
                          Text(
                            'Image not found on device',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

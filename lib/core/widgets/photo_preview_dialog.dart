import 'dart:io';
import 'package:flutter/material.dart';
import '../services/attachment_service.dart';
import '../theme/app_colors.dart';

class PhotoPreviewDialog extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final String? title;

  PhotoPreviewDialog({
    super.key,
    required String imagePath,
    this.title,
  })  : imagePaths = [imagePath],
        initialIndex = 0;

  const PhotoPreviewDialog.multiple({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
    this.title,
  });

  static Future<void> show(
    BuildContext context, {
    String? imagePath,
    List<String>? imagePaths,
    int initialIndex = 0,
    String? title,
  }) {
    final paths = imagePaths ?? (imagePath != null ? [imagePath] : <String>[]);
    if (paths.isEmpty) return Future.value();

    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => PhotoPreviewDialog.multiple(
        imagePaths: paths,
        initialIndex: initialIndex.clamp(0, paths.length - 1),
        title: title,
      ),
    );
  }

  @override
  State<PhotoPreviewDialog> createState() => _PhotoPreviewDialogState();
}

class _PhotoPreviewDialogState extends State<PhotoPreviewDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imagePaths.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Bar with Title, Counter and Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title ?? 'Receipt / Photo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (total > 1)
                      Text(
                        'Photo ${_currentIndex + 1} of $total',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Image View / PageView
          Flexible(
            child: SizedBox(
              height: 420,
              child: PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: (idx) {
                  setState(() => _currentIndex = idx);
                },
                itemBuilder: (ctx, idx) {
                  final path = widget.imagePaths[idx];
                  return FutureBuilder<File?>(
                    future: AttachmentService.resolveFile(path),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      final file = snapshot.data;
                      if (file == null || !file.existsSync()) {
                        return Container(
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
                  );
                },
              ),
            ),
          ),

          // Indicator dots if multiple
          if (total > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (dotIdx) {
                final isSelected = dotIdx == _currentIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

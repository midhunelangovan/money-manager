import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/attachment_service.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import 'photo_preview_dialog.dart';

/// Unified reusable Photo / Receipt Attachment component for Kal's Money Manager.
/// Supports Expense, Income, Transfer, and Recurring transaction forms.
class TransactionAttachment extends StatelessWidget {
  final String? receiptPath;
  final ValueChanged<String?> onAttachmentChanged;
  final String label;
  final bool enabled;

  const TransactionAttachment({
    super.key,
    required this.receiptPath,
    required this.onAttachmentChanged,
    this.label = 'Photo / Receipt',
    this.enabled = true,
  });

  void _showImagePickerOptions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text(
                  'Attach Photo / Receipt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Divider(color: isDark ? AppColors.darkBorderSubtle : null),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                  child: Icon(Icons.photo_camera_rounded, color: isDark ? theme.colorScheme.primary : AppColors.primary),
                ),
                title: Text(
                  'Take Photo (Camera)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await AttachmentService.pickAndSaveImage(ImageSource.camera);
                  if (path != null) {
                    onAttachmentChanged(path);
                  }
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.primaryContainer,
                  child: Icon(Icons.photo_library_rounded, color: isDark ? theme.colorScheme.primary : AppColors.primary),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await AttachmentService.pickAndSaveImage(ImageSource.gallery);
                  if (path != null) {
                    onAttachmentChanged(path);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAttachment = receiptPath != null && receiptPath!.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              if (hasAttachment && enabled)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => onAttachmentChanged(null),
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasAttachment)
            InkWell(
              onTap: enabled ? () => _showImagePickerOptions(context) : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.primaryLight),
                    SizedBox(width: 8),
                    Text(
                      '+ Add Photo / Receipt',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: () => PhotoPreviewDialog.show(context, imagePath: receiptPath!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: FutureBuilder<File?>(
                        future: AttachmentService.resolveFile(receiptPath),
                        builder: (context, snapshot) {
                          final file = snapshot.data;
                          if (file != null && file.existsSync()) {
                            return Image.file(file, fit: BoxFit.cover);
                          }
                          return Container(
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                            child: const Icon(Icons.image_outlined, size: 26, color: AppColors.lightTextMuted),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photo Attached',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => PhotoPreviewDialog.show(context, imagePath: receiptPath!),
                        child: const Text(
                          'Tap thumbnail to preview',
                          style: TextStyle(fontSize: 11.5, color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showImagePickerOptions(context),
                    child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

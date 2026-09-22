import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/image_helper.dart';

class AppImageView extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double? fallbackIconSize;
  final Color? fallbackColor;
  final Color? fallbackBackgroundColor;

  const AppImageView({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackIconSize,
    this.fallbackColor,
    this.fallbackBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(12);

    Widget content;
    final imageStr = imageUrl?.trim();

    if (imageStr == null || imageStr.isEmpty) {
      content = _buildFallback();
    } else if (ImageHelper.isBase64Image(imageStr)) {
      final Uint8List? bytes = ImageHelper.bytesFromBase64(imageStr);
      if (bytes != null && bytes.isNotEmpty) {
        content = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      } else {
        content = _buildFallback();
      }
    } else if (imageStr.startsWith('http://') || imageStr.startsWith('https://')) {
      content = Image.network(
        imageStr,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          );
        },
      );
    } else if (!kIsWeb && (imageStr.startsWith('/') || imageStr.contains(':\\'))) {
      final file = File(imageStr);
      if (file.existsSync()) {
        content = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      } else {
        content = _buildFallback();
      }
    } else {
      content = _buildFallback();
    }

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: fallbackBackgroundColor ?? AppColors.surfaceVariant,
          borderRadius: effectiveRadius,
        ),
        child: content,
      ),
    );
  }

  Widget _buildFallback() {
    final double iconSize = fallbackIconSize ??
        ((height != null && height!.isFinite) ? (height! * 0.35).clamp(18.0, 36.0) : 24.0);
    return Center(
      child: Icon(
        fallbackIcon,
        color: fallbackColor ?? AppColors.textMuted,
        size: iconSize,
      ),
    );
  }
}

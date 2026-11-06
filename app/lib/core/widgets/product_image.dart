import 'dart:io';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? imagePath;
  final String? productName;
  final double width;
  final double height;
  final double borderRadius;
  final IconData defaultIcon;

  const ProductImage({
    super.key,
    required this.imagePath,
    this.productName,
    this.width = 60,
    this.height = 60,
    this.borderRadius = 12,
    this.defaultIcon = Icons.inventory_2_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      final path = imagePath!;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.network(
            path,
            width: width,
            height: height,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: width,
                height: height,
                color: const Color(0xFFF1F5F9),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
            errorBuilder: (_, _, _) => _buildPlaceholder(),
          ),
        );
      } else {
        final file = File(path);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.file(
              file,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPlaceholder(),
            ),
          );
        }
      }
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final (colors, icon) = _getGradientAndIcon(productName);
    final iconSize = width.isFinite && width > 0 ? (width * 0.38).clamp(18.0, 44.0) : 32.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  (List<Color>, IconData) _getGradientAndIcon(String? name) {
    if (name == null) {
      return (
        [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
        defaultIcon,
      );
    }

    final lower = name.toLowerCase();
    if (lower.contains('кофе') || lower.contains('капучино') || lower.contains('американо') || lower.contains('латте')) {
      return (
        [const Color(0xFF78350F), const Color(0xFFB45309)],
        Icons.coffee_rounded,
      );
    } else if (lower.contains('круассан') || lower.contains('выпечка') || lower.contains('булочка') || lower.contains('хлеб')) {
      return (
        [const Color(0xFFD97706), const Color(0xFFF59E0B)],
        Icons.bakery_dining_rounded,
      );
    } else if (lower.contains('сэндвич') || lower.contains('бургер') || lower.contains('еда') || lower.contains('донер')) {
      return (
        [const Color(0xFFEA580C), const Color(0xFFFB923C)],
        Icons.lunch_dining_rounded,
      );
    } else if (lower.contains('вода') || lower.contains('сок') || lower.contains('напиток') || lower.contains('cola')) {
      return (
        [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
        Icons.water_drop_rounded,
      );
    } else if (lower.contains('кабель') || lower.contains('заряд') || lower.contains('type-c') || lower.contains('usb')) {
      return (
        [const Color(0xFF334155), const Color(0xFF64748B)],
        Icons.cable_rounded,
      );
    } else if (lower.contains('чехол') || lower.contains('стекло') || lower.contains('телефон')) {
      return (
        [const Color(0xFF4F46E5), const Color(0xFF818CF8)],
        Icons.phone_android_rounded,
      );
    } else if (lower.contains('шоколад') || lower.contains('батончик') || lower.contains('печенье') || lower.contains('сладост')) {
      return (
        [const Color(0xFF451A03), const Color(0xFF78350F)],
        Icons.cookie_rounded,
      );
    }

    return (
      [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
      Icons.shopping_bag_outlined,
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';

class MediaImage extends StatelessWidget {
  const MediaImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorIcon = const Icon(Icons.image_not_supported),
  });

  final String? path;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget errorIcon;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (path == null || path!.isEmpty) {
      child = placeholder ?? Center(child: errorIcon);
    } else if (path!.startsWith('http')) {
      child = Image.network(
        path!,
        fit: fit,
        errorBuilder: (_, __, ___) => Center(child: errorIcon),
      );
    } else {
      // Local file or asset
      try {
        final f = File(path!);
        if (f.existsSync()) {
          child = Image.file(f, fit: fit);
        } else {
          child = Image.asset(path!, fit: fit,
              errorBuilder: (_, __, ___) => Center(child: errorIcon));
        }
      } catch (_) {
        child = Image.asset(path!, fit: fit,
            errorBuilder: (_, __, ___) => Center(child: errorIcon));
      }
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

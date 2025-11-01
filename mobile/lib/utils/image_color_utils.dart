import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Utilities for extracting colors from images
class ImageColorUtils {
  /// Determines if white icons should be used on the image background
  /// Returns true if the image is dark (use white icons), false if light (use black icons)
  static Future<bool> shouldUseWhiteIcons(ImageProvider imageProvider) async {
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100), // Small size for faster processing
        maximumColorCount: 10,
      );

      // Get the dominant color or fallback to a default
      final dominantColor = paletteGenerator.dominantColor?.color ?? Colors.grey;

      // Calculate luminance to determine if the color is dark or light
      // Luminance range: 0.0 (black) to 1.0 (white)
      final luminance = dominantColor.computeLuminance();

      // If luminance is less than 0.5, the color is dark, use white icons
      return luminance < 0.5;
    } catch (e) {
      debugPrint('Error detecting image color: $e');
      // Default to white icons on error
      return true;
    }
  }

  /// Gets the dominant color from an image
  static Future<Color?> getDominantColor(ImageProvider imageProvider) async {
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100),
        maximumColorCount: 10,
      );

      return paletteGenerator.dominantColor?.color;
    } catch (e) {
      debugPrint('Error getting dominant color: $e');
      return null;
    }
  }

  /// Gets a vibrant color from an image (useful for accents)
  static Future<Color?> getVibrantColor(ImageProvider imageProvider) async {
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100),
        maximumColorCount: 10,
      );

      return paletteGenerator.vibrantColor?.color;
    } catch (e) {
      debugPrint('Error getting vibrant color: $e');
      return null;
    }
  }
}

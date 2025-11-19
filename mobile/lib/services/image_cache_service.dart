import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service to handle image compression and local caching
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  Directory? _cacheDirectory;

  /// Initialize the cache directory
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory(path.join(appDir.path, 'image_cache'));

    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
  }

  /// Compress an image file and cache it locally
  /// Returns the compressed file or null if compression fails
  Future<File?> compressAndCacheImage({
    required File imageFile,
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      // Ensure cache directory is initialized
      if (_cacheDirectory == null) {
        await initialize();
      }

      // Generate a unique filename based on original file path and parameters
      final hash = md5.convert(
        utf8.encode('${imageFile.path}_$quality\_$maxWidth\_$maxHeight')
      ).toString();
      final extension = path.extension(imageFile.path).toLowerCase();
      final targetExtension = (extension == '.webp' || extension == '.jpg' || extension == '.jpeg')
          ? extension
          : '.jpg';
      final cachedFileName = '$hash$targetExtension';
      final cachedFilePath = path.join(_cacheDirectory!.path, cachedFileName);

      // Check if already cached
      final cachedFile = File(cachedFilePath);
      if (await cachedFile.exists()) {
        return cachedFile;
      }

      // Compress the image
      final compressedData = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: targetExtension == '.webp' ? CompressFormat.webp : CompressFormat.jpeg,
      );

      if (compressedData == null) {
        return null;
      }

      // Write compressed data to cache
      await cachedFile.writeAsBytes(compressedData);

      return cachedFile;
    } catch (e) {
      // Log error in debug mode
      assert(() {
        print('Error compressing image: $e');
        return true;
      }());
      return null;
    }
  }

  /// Get the size of an image file in bytes
  Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// Format bytes to human-readable string
  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    if (_cacheDirectory == null) {
      await initialize();
    }

    if (await _cacheDirectory!.exists()) {
      await _cacheDirectory!.delete(recursive: true);
      await _cacheDirectory!.create(recursive: true);
    }
  }

  /// Get total cache size
  Future<int> getCacheSize() async {
    if (_cacheDirectory == null) {
      await initialize();
    }

    if (!await _cacheDirectory!.exists()) {
      return 0;
    }

    int totalSize = 0;
    await for (var entity in _cacheDirectory!.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }
}

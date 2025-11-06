import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

class ShareHandlerService {
  static final ShareHandlerService _instance = ShareHandlerService._internal();
  factory ShareHandlerService() => _instance;
  ShareHandlerService._internal();

  StreamSubscription? _intentDataStreamSubscription;
  final StreamController<SharedContent> _sharedContentController =
      StreamController<SharedContent>.broadcast();

  Stream<SharedContent> get sharedContentStream =>
      _sharedContentController.stream;

  /// Initialize the share handler service
  void initialize() {
    // Listen for shared content (text, URLs, images) while app is in memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          _handleSharedMedia(value);
        }
      },
      onError: (err) {
        // Error receiving shared media
      },
    );

    // Get the initial shared content when app is launched from share
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedMedia(value);
      }
    });
  }

  void _handleSharedMedia(List<SharedMediaFile> mediaFiles) {
    final file = mediaFiles.first;
    final path = file.path;

    // First, check if it's a direct URL (shared text containing a URL)
    if (_isValidUrl(path)) {
      // Ignore jinnie.app URLs - these should be handled by DeepLinkService
      if (_isJinnieAppUrl(path)) {
        debugPrint('🔗 Ignoring jinnie.app URL in share handler (deep link): $path');
        return;
      }

      _sharedContentController.add(SharedContent(
        type: SharedContentType.url,
        url: path,
      ));
      return;
    }

    // Check if thumbnail contains a URL (alternative way text/URLs are shared)
    if (file.thumbnail != null && _isValidUrl(file.thumbnail!)) {
      _sharedContentController.add(SharedContent(
        type: SharedContentType.url,
        url: file.thumbnail,
      ));
      return;
    }

    // Check the path extension to determine if it's an image file
    final extension = path.split('.').last.toLowerCase();
    if (_isImageExtension(extension)) {
      _sharedContentController.add(SharedContent(
        type: SharedContentType.image,
        imagePath: path,
      ));
      return;
    }

    // If it's plain text (not a URL), emit it as text
    if (path.isNotEmpty) {
      _sharedContentController.add(SharedContent(
        type: SharedContentType.text,
        text: path,
      ));
    }
  }

  bool _isImageExtension(String extension) {
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(extension);
  }

  bool _isValidUrl(String text) {
    try {
      final uri = Uri.parse(text);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clean up resources
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _sharedContentController.close();

    // Clear initial shared content
    ReceiveSharingIntent.instance.reset();
  }

  /// Clear any pending shared content
  void clearSharedContent() {
    ReceiveSharingIntent.instance.reset();
  }
}

enum SharedContentType {
  url,
  image,
  text,
}

class SharedContent {
  final SharedContentType type;
  final String? url;
  final String? imagePath;
  final String? text;

  SharedContent({
    required this.type,
    this.url,
    this.imagePath,
    this.text,
  });
}

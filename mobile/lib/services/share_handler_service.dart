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
    // Listen for shared content while app is in memory
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

    // Check the path extension to determine file type
    final path = file.path;
    final extension = path.split('.').last.toLowerCase();

    if (_isImageExtension(extension)) {
      _sharedContentController.add(SharedContent(
        type: SharedContentType.image,
        imagePath: path,
      ));
    } else {
      // For URLs or text content, check if it's in the thumbnail
      if (file.thumbnail != null && _isValidUrl(file.thumbnail!)) {
        _sharedContentController.add(SharedContent(
          type: SharedContentType.url,
          url: file.thumbnail,
        ));
      } else if (_isValidUrl(path)) {
        _sharedContentController.add(SharedContent(
          type: SharedContentType.url,
          url: path,
        ));
      }
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

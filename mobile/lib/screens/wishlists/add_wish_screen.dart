import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../services/wishlist_service.dart';
import '../../services/api_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../common/navigation/native_page_route.dart';
import '../../common/widgets/add_item_tip_bottom_sheet.dart';
import '../../widgets/cached_image.dart';
import 'widgets/wish_form_widgets.dart';

class AddWishScreen extends StatefulWidget {
  final String? wishlistId;
  final String? initialUrl;
  final Map<String, dynamic>? prefilledData;
  final String? source; // Track source: 'homepage' or 'inspo'

  const AddWishScreen({
    super.key,
    this.wishlistId,
    this.initialUrl,
    this.prefilledData,
    this.source,
  });

  /// Show as bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    String? wishlistId,
    String? initialUrl,
    Map<String, dynamic>? prefilledData,
    String? source,
  }) async {
    // Show the add item screen
    final result = await NativeTransitions.showNativeModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      child: AddWishScreen(
        wishlistId: wishlistId,
        initialUrl: initialUrl,
        prefilledData: prefilledData,
        source: source,
      ),
    );

    // If successful save from homepage and user hasn't seen tip, show it
    if (result == true && source == 'homepage') {
      final preferencesService = PreferencesService();

      debugPrint('🎯 AddWishScreen: Checking share tip conditions...');
      debugPrint('  - Result: $result');
      debugPrint('  - Source: $source');
      debugPrint('  - Has seen tip: ${preferencesService.hasSeenAddItemTip}');

      if (!preferencesService.hasSeenAddItemTip) {
        debugPrint('✅ Showing share tip bottom sheet');
        // Mark as seen
        await preferencesService.setHasSeenAddItemTip(true);

        // Wait a brief moment for context to stabilize after bottom sheet dismissal
        await Future.delayed(const Duration(milliseconds: 100));

        // Show the tip after successful save
        if (context.mounted) {
          debugPrint('✅ Context is mounted, showing tip');
          await AddItemTipBottomSheet.show(context);
        } else {
          debugPrint('⚠️ Context not mounted, cannot show tip');
        }
      } else {
        debugPrint('⏭️ User has already seen share tip, skipping');
      }
    } else {
      debugPrint('❌ Share tip conditions not met:');
      debugPrint('  - Result: $result');
      debugPrint('  - Source: $source');
    }

    return result;
  }

  @override
  State<AddWishScreen> createState() => _AddWishScreenState();
}

class _AddWishScreenState extends State<AddWishScreen> {
  // Platform channel for clipboard
  static const platform = MethodChannel('com.wishlists.gifts/clipboard');

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _urlController = TextEditingController();

  // Focus nodes
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _urlFocusNode = FocusNode();

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  // Form state
  File? _selectedImage;
  String? _scrapedImageUrl;
  String _currency = 'USD';
  bool _isLoading = false;
  bool _isScrapingUrl = false;
  String? _selectedWishlistId;
  String? _lastScrapedUrl;

  // Visible fields tracking
  final Set<String> _visibleFields = {};

  // Currency list will be populated in initState based on user locale
  List<String> _currencies = [];

  @override
  void initState() {
    super.initState();

    // Initialize currencies based on user locale
    _initializeCurrencies();

    // Auto-focus title field after a short delay ONLY if no prefilled data
    if (widget.prefilledData == null && widget.initialUrl == null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _titleFocusNode.requestFocus();
        }
      });
    }

    // Listen for title changes to enable/disable save button
    _titleController.addListener(() {
      setState(() {});
    });

    // Listen for URL changes with debouncing
    _urlController.addListener(_onUrlChanged);

    // Pre-fill data if provided (from feed copy)
    if (widget.prefilledData != null) {
      final data = widget.prefilledData!;

      // Title - always required
      _titleController.text = data['title'] ?? '';

      // Description - check if not empty
      final descriptionValue = data['description'];
      if (descriptionValue != null && descriptionValue.toString().trim().isNotEmpty) {
        _descriptionController.text = descriptionValue.toString().trim();
        _visibleFields.add('description');
      }

      // Price - check if not null and show field
      final priceValue = data['price'];
      if (priceValue != null) {
        _priceController.text = priceValue.toString();
        _visibleFields.add('price');
      }

      // Currency - set if provided
      _currency = data['currency'] ?? 'USD';

      // URL - ensure it's properly set and visible
      final urlValue = data['url'];
      if (urlValue != null && urlValue.toString().trim().isNotEmpty) {
        _urlController.text = urlValue.toString().trim();
        _visibleFields.add('url');
        // Mark as last scraped to prevent auto-scraping
        _lastScrapedUrl = urlValue.toString().trim();
      }

      // Image - validate before setting
      // Support both local file paths (from sharing) and URLs (from feed copy)
      final imageValue = data['image'];
      if (imageValue != null && imageValue.toString().trim().isNotEmpty) {
        final imagePath = imageValue.toString().trim();

        // Check if it's a URL or a local file path
        if (_isValidUrl(imagePath)) {
          // It's a URL - use for scraped image
          _scrapedImageUrl = imagePath;
        } else {
          // It's a file path - load as selected image
          final file = File(imagePath);
          if (file.existsSync()) {
            _selectedImage = file;
          } else {
            debugPrint('⚠️ Prefilled image file does not exist: $imagePath');
          }
        }
        _visibleFields.add('image');
      }
    }
    // Otherwise pre-fill URL if provided from share or clipboard
    else if (widget.initialUrl != null) {
      // Check if the URL is an image URL (pattern matching)
      if (_isImageUrl(widget.initialUrl!)) {
        // It's an image URL, treat as image
        _scrapedImageUrl = widget.initialUrl!;
        _visibleFields.add('image');
      } else {
        // Check if it's an image via HTTP Content-Type
        Future.delayed(const Duration(milliseconds: 100), () async {
          if (!mounted) return;

          final isImage = await _checkIfUrlIsImage(widget.initialUrl!);

          if (mounted && isImage) {
            // It's an image, set as image
            setState(() {
              _scrapedImageUrl = widget.initialUrl!;
              _visibleFields.add('image');
            });
          } else if (mounted) {
            // Regular URL, add to URL field and trigger scraping
            setState(() {
              _urlController.text = widget.initialUrl!;
              _visibleFields.add('url');
            });
            // Trigger scraping after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _scrapeUrl(widget.initialUrl!);
              }
            });
          }
        });
      }
    }

    // Pre-select wishlist with priority:
    // 1. Widget parameter (if provided)
    // 2. Last used wishlist (from preferences)
    // 3. First available wishlist
    _selectedWishlistId = widget.wishlistId;

    // Auto-select wishlist after a short delay if none is pre-selected
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _selectedWishlistId == null) {
        final wishlistService = context.read<WishlistService>();
        final preferencesService = PreferencesService();

        if (wishlistService.wishlists.isNotEmpty) {
          String? wishlistToSelect;

          // Try to use last used wishlist if it still exists
          final lastUsedId = preferencesService.lastUsedWishlistId;
          if (lastUsedId != null) {
            final lastUsedExists = wishlistService.wishlists.any((w) => w.id == lastUsedId);
            if (lastUsedExists) {
              wishlistToSelect = lastUsedId;
            }
          }

          // Fall back to first wishlist if last used doesn't exist
          wishlistToSelect ??= wishlistService.wishlists.first.id;

          setState(() {
            _selectedWishlistId = wishlistToSelect;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _priceFocusNode.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  /// Initialize currencies with user's locale currency at top
  void _initializeCurrencies() {
    // All available currencies
    const allCurrencies = [
      'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'SEK', 'NZD',
      'MXN', 'SGD', 'HKD', 'NOK', 'KRW', 'TRY', 'RUB', 'INR', 'BRL', 'ZAR',
      'DKK', 'PLN', 'THB', 'IDR', 'HUF', 'CZK', 'ILS', 'CLP', 'PHP', 'AED',
      'COP', 'SAR', 'MYR', 'RON'
    ];

    // Get user's locale
    final locale = Platform.localeName; // e.g., 'en_US', 'fr_FR'
    final countryCode = locale.split('_').length > 1 ? locale.split('_')[1] : 'US';

    // Map country codes to currencies
    final countryToCurrency = {
      'US': 'USD', 'GB': 'GBP', 'EU': 'EUR', 'DE': 'EUR', 'FR': 'EUR', 'IT': 'EUR',
      'ES': 'EUR', 'NL': 'EUR', 'BE': 'EUR', 'AT': 'EUR', 'PT': 'EUR', 'IE': 'EUR',
      'JP': 'JPY', 'CA': 'CAD', 'AU': 'AUD', 'CH': 'CHF', 'CN': 'CNY', 'SE': 'SEK',
      'NZ': 'NZD', 'MX': 'MXN', 'SG': 'SGD', 'HK': 'HKD', 'NO': 'NOK', 'KR': 'KRW',
      'TR': 'TRY', 'RU': 'RUB', 'IN': 'INR', 'BR': 'BRL', 'ZA': 'ZAR', 'DK': 'DKK',
      'PL': 'PLN', 'TH': 'THB', 'ID': 'IDR', 'HU': 'HUF', 'CZ': 'CZK', 'IL': 'ILS',
      'CL': 'CLP', 'PH': 'PHP', 'AE': 'AED', 'CO': 'COP', 'SA': 'SAR', 'MY': 'MYR',
      'RO': 'RON'
    };

    // Get user's currency
    final userCurrency = countryToCurrency[countryCode] ?? 'USD';
    _currency = userCurrency;

    // Build currency list with user's currency first
    _currencies = [userCurrency];
    for (final currency in allCurrencies) {
      if (currency != userCurrency) {
        _currencies.add(currency);
      }
    }
  }

  /// Listener for URL field changes with debouncing
  void _onUrlChanged() {
    final url = _urlController.text.trim();

    if (url.isEmpty || url == _lastScrapedUrl) {
      return;
    }

    // Check if it's a valid URL
    if (_isValidUrl(url)) {
      // Debounce: wait for user to stop typing
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _urlController.text.trim() == url && url != _lastScrapedUrl) {
          _scrapeUrl(url);
        }
      });
    }
  }

  /// Validate if string is a valid HTTP(S) URL
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

  /// Smart paste from clipboard - handles images, URLs, and text
  Future<void> _pasteFromClipboard() async {
    // Light haptic feedback when paste is triggered
    HapticFeedback.lightImpact();

    try {
      // 1. Check for image in clipboard (via platform channel)
      final imagePath = await _getClipboardImage();

      // 2. Get text from clipboard
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();

      // 3. Handle based on what we found

      // If both image and text/URL exist, prefill both
      if (imagePath != null && text != null && text.isNotEmpty) {
        setState(() {
          // Set the image
          _selectedImage = File(imagePath);
          _visibleFields.add('image');

          // Set the URL/text
          if (_isValidUrl(text)) {
            _urlController.text = text;
            _visibleFields.add('url');
            // Trigger scraping
            _scrapeUrl(text);
          } else if (_titleController.text.isEmpty) {
            // Plain text → title
            _titleController.text = text;
          }
        });
        return;
      }

      // Only image found
      if (imagePath != null) {
        setState(() {
          _selectedImage = File(imagePath);
          _visibleFields.add('image');
        });
        return;
      }

      // Only text found
      if (text != null && text.isNotEmpty) {
        // Check if it's an image URL
        if (_isImageUrl(text)) {
          setState(() {
            _scrapedImageUrl = text;
            _visibleFields.add('image');
          });
          return;
        }

        // Check if it's a valid URL
        if (_isValidUrl(text)) {
          // Try to detect if it's an image by checking HTTP headers
          final isImage = await _checkIfUrlIsImage(text);

          if (isImage) {
            // It's an image, set as image URL only
            setState(() {
              _scrapedImageUrl = text;
              _visibleFields.add('image');
            });
            return;
          }

          // Not an image, treat as regular URL for scraping
          setState(() {
            _urlController.text = text;
            _visibleFields.add('url');
          });
          // Request focus after adding field
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _urlFocusNode.requestFocus();
            }
          });
          // Trigger scraping
          _scrapeUrl(text);
          return;
        }

        // Plain text → title (if empty)
        if (_titleController.text.isEmpty) {
          setState(() {
            _titleController.text = text;
          });
        }
      }
    } catch (e) {
      debugPrint('Error pasting from clipboard: $e');
    }
  }

  /// Get image from clipboard via platform channel
  Future<String?> _getClipboardImage() async {
    try {
      final result = await platform.invokeMethod<String>('getClipboardImage');
      if (result != null && result.isNotEmpty) {
        debugPrint('✅ Got image from clipboard: $result');
        return result;
      }
    } catch (e) {
      debugPrint('Error getting clipboard image: $e');
    }
    return null;
  }

  /// Check if URL is an image by fetching HTTP headers
  Future<bool> _checkIfUrlIsImage(String url) async {
    try {
      // Make a HEAD request to check Content-Type without downloading the full file
      final response = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          return http.Response('', 408); // Request timeout
        },
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type']?.toLowerCase() ?? '';
        debugPrint('Content-Type for $url: $contentType');

        // Check if it's an image MIME type
        if (contentType.startsWith('image/')) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error checking if URL is image: $e');
    }
    return false;
  }

  /// Check if text is an image URL
  bool _isImageUrl(String text) {
    try {
      final uri = Uri.parse(text);
      final host = uri.host.toLowerCase();
      final path = uri.path.toLowerCase();

      // Check for direct image file extensions
      if (path.endsWith('.jpg') ||
          path.endsWith('.jpeg') ||
          path.endsWith('.png') ||
          path.endsWith('.gif') ||
          path.endsWith('.webp') ||
          path.endsWith('.bmp')) {
        return true;
      }

      // Check for known image hosting domains
      final imageHosts = [
        'gstatic.com',           // Google Images CDN
        'googleusercontent.com', // Google User Content
        'imgur.com',             // Imgur
        'i.imgur.com',           // Imgur direct
        'ibb.co',                // ImgBB
        'imgbb.com',             // ImgBB
        'postimg.cc',            // PostImage
        'flickr.com',            // Flickr
        'staticflickr.com',      // Flickr CDN
        'pinimg.com',            // Pinterest
        'cloudinary.com',        // Cloudinary CDN
        'amazonaws.com',         // AWS S3 (common for images)
      ];

      for (final imageHost in imageHosts) {
        if (host.contains(imageHost)) {
          return true;
        }
      }

      // Check query parameters for image indicators
      if (path.contains('/image') ||
          path.contains('/img') ||
          path.contains('/photo')) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Scrape URL and auto-fill form fields
  Future<void> _scrapeUrl(String url) async {
    if (_isScrapingUrl) return;

    setState(() {
      _isScrapingUrl = true;
      _lastScrapedUrl = url;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.scrapeUrl(url);

      if (!mounted) return;

      if (response.success && response.metadata != null) {
        final metadata = response.metadata!;

        // Auto-fill title if empty
        if (_titleController.text.isEmpty && metadata.title != null) {
          _titleController.text = metadata.title!;
        }

        // Auto-fill description
        if (_descriptionController.text.isEmpty && metadata.description != null) {
          _descriptionController.text = metadata.description!;
          _visibleFields.add('description');
        }

        // Auto-fill price
        if (_priceController.text.isEmpty && metadata.price != null) {
          _priceController.text = metadata.price!.toStringAsFixed(2);
          if (metadata.currency != null) {
            _currency = metadata.currency!;
          }
          _visibleFields.add('price');
        }

        // Store scraped image URL
        if (metadata.image != null) {
          _scrapedImageUrl = metadata.image;
          _visibleFields.add('image');
        }

        setState(() {});

        // Haptic feedback when scraping completes successfully
        HapticFeedback.selectionClick();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      metadata.source == 'amazon'
                          ? '✨ Product details loaded from Amazon!'
                          : metadata.source == 'bestbuy'
                          ? '✨ Product details loaded from BestBuy!'
                          : '✨ Product details loaded!',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        // Show failure message
        debugPrint('URL scraping failed: ${response.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Could not load product details from link'),
                ),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error scraping URL: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScrapingUrl = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    // Show bottom sheet to choose between camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Camera option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppTheme.primaryAccent,
                    ),
                  ),
                  title: Text(
                    'ui.photo_picker_take_photo'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'ui.photo_picker_use_camera'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 8),
                // Gallery option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: AppTheme.primaryAccent,
                    ),
                  ),
                  title: Text(
                    'ui.photo_picker_choose_gallery'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'ui.photo_picker_select_photos'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      // Use imageQuality and size constraints in pickImage for faster initial compression
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null && mounted) {
        // Crop the image before using it
        await _cropImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        _showPermissionDeniedDialog();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('permissions.camera_photo_required'.tr()),
        content: Text(
          'permissions.camera_photo_message_wish'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('app.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('permissions.open_settings'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _cropImage(String imagePath) async {
    final theme = Theme.of(context);
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'wish.crop_image'.tr(),
          toolbarColor: theme.colorScheme.surface,
          toolbarWidgetColor: theme.colorScheme.onSurface,
          statusBarLight: theme.brightness == Brightness.light,
          backgroundColor: theme.colorScheme.surface,
          activeControlsWidgetColor: AppTheme.primaryAccent,
          lockAspectRatio: false,
          hideBottomControls: false,
          showCropGrid: true,
          dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
        ),
        IOSUiSettings(
          title: 'wish.crop_image'.tr(),
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
          aspectRatioPickerButtonHidden: false,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: true,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _selectedImage = File(croppedFile.path);
        _visibleFields.add('image');
      });
    }
  }

  Future<void> _saveWish() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorMessage('wish.title_required'.tr());
      return;
    }

    // Haptic feedback when save is triggered
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      final price = _priceController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceController.text.trim());

      await context.read<WishlistService>().addWish(
        wishlistId: _selectedWishlistId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: price,
        currency: _currency,
        url: _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        imageFile: _selectedImage,
        images: _selectedImage == null && _scrapedImageUrl != null
            ? [_scrapedImageUrl!]
            : null,
      );

      // Save the selected wishlist as last used for future use
      if (_selectedWishlistId != null) {
        await PreferencesService().setLastUsedWishlistId(_selectedWishlistId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('wish.created_successfully'.tr()),
            backgroundColor: AppTheme.primaryAccent,
            duration: const Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('wish.create_failed'.tr());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field - Always visible, big and borderless
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: WishFormTextField(
                          controller: _titleController,
                          focusNode: _titleFocusNode,
                          hintText: 'wish.title_placeholder'.tr(),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          maxLines: 2,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),

                  // Description Field (if visible)
                  if (_visibleFields.contains('description')) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: WishFormTextField(
                            controller: _descriptionController,
                            focusNode: _descriptionFocusNode,
                            hintText: 'Description',
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        WishFieldCloseButton(
                          onTap: () {
                            setState(() {
                              _visibleFields.remove('description');
                              _descriptionController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ],

                  // URL Field (if visible)
                  if (_visibleFields.contains('url')) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: WishFormTextField(
                            controller: _urlController,
                            focusNode: _urlFocusNode,
                            hintText: 'Link',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            keyboardType: TextInputType.url,
                            textColor: Colors.grey[600],
                          ),
                        ),
                        if (_isScrapingUrl)
                          const Padding(
                            padding: EdgeInsets.only(left: 8, top: 4),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          WishFieldCloseButton(
                            onTap: () {
                              setState(() {
                                _visibleFields.remove('url');
                                _urlController.clear();
                                // Don't clear _scrapedImageUrl - image and URL are independent
                              });
                            },
                          ),
                      ],
                    ),
                  ],

                  // Image Field (if visible)
                  if (_visibleFields.contains('image')) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: (_selectedImage != null || _scrapedImageUrl != null)
                                ? _buildImagePreview()
                                : _buildAddImageButton(),
                          ),
                          WishFieldCloseButton(
                            onTap: () {
                              setState(() {
                                _visibleFields.remove('image');
                                _selectedImage = null;
                                _scrapedImageUrl = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Price Field (if visible)
                  if (_visibleFields.contains('price')) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                CurrencyHelper.getSymbol(_currency),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: WishFormTextField(
                                  controller: _priceController,
                                  focusNode: _priceFocusNode,
                                  hintText: '0.00',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              DropdownButton<String>(
                                value: _currency,
                                underline: const SizedBox(),
                                items: _currencies.map((currency) {
                                  return DropdownMenuItem(
                                    value: currency,
                                    child: Text(
                                      currency,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _currency = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        WishFieldCloseButton(
                          onTap: () {
                            setState(() {
                              _visibleFields.remove('price');
                              _priceController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ],

                  // Wishlist Selector
                  const SizedBox(height: 20),
                  Text(
                    'List',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  WishlistSelector(
                    selectedWishlistId: _selectedWishlistId,
                    onWishlistSelected: (id) {
                      setState(() {
                        _selectedWishlistId = id;
                      });
                    },
                    onCreateNew: () async {
                      final newId = await createNewWishlist(context);
                      if (newId != null && mounted) {
                        setState(() {
                          _selectedWishlistId = newId;
                        });
                      }
                    },
                  ),

                  // Add More Details buttons
                  WishFieldButtons(
                    visibleFields: _visibleFields,
                    onFieldAdd: (fieldKey) {
                      setState(() {
                        _visibleFields.add(fieldKey);
                      });

                      // Request focus or perform action after setState
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (!mounted) return;
                        if (fieldKey == 'image') {
                          _pickImage();
                        } else if (fieldKey == 'description') {
                          _descriptionFocusNode.requestFocus();
                        } else if (fieldKey == 'url') {
                          _urlFocusNode.requestFocus();
                        } else if (fieldKey == 'price') {
                          _priceFocusNode.requestFocus();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              bottomPadding > 0 ? bottomPadding + 12 : safeAreaBottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _pasteFromClipboard,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.content_paste, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'add_wish.paste'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: (_isLoading || _titleController.text.trim().isEmpty) ? null : _saveWish,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: AppTheme.primaryAccent,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'app.save'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _selectedImage != null
              ? Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                )
              : _scrapedImageUrl != null
                  ? CachedImageWidget(
                      imageUrl: _scrapedImageUrl,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                    )
                  : const SizedBox(),
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Tap to add photo',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWishlistSelection() async {
    final wishlistService = context.read<WishlistService>();
    await wishlistService.fetchWishlists();
    final wishlists = wishlistService.wishlists;

    if (!mounted) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    'wish.select_wishlist'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (wishlists.isNotEmpty)
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: wishlists.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final wishlist = wishlists[index];
                        final isSelected = _selectedWishlistId == wishlist.id;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop(wishlist.id);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryAccent.withValues(alpha: 0.08)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryAccent.withValues(alpha: 0.3)
                                      : Colors.grey[200]!,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      wishlist.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppTheme.primaryAccent
                                            : AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.primaryAccent,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedWishlistId = result;
      });
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import '../../services/wishlist_service.dart';
import '../../services/image_cache_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../models/wishlist.dart';
import '../../common/navigation/native_page_route.dart';
import 'wishlist_new_screen.dart';

class AddWishScreen extends StatefulWidget {
  final String? wishlistId;
  final String? initialUrl;
  final Map<String, dynamic>? prefilledData;

  const AddWishScreen({
    super.key,
    this.wishlistId,
    this.initialUrl,
    this.prefilledData,
  });

  /// Show as bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    String? wishlistId,
    String? initialUrl,
    Map<String, dynamic>? prefilledData,
  }) {
    return NativeTransitions.showNativeModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      child: AddWishScreen(
        wishlistId: wishlistId,
        initialUrl: initialUrl,
        prefilledData: prefilledData,
      ),
    );
  }

  @override
  State<AddWishScreen> createState() => _AddWishScreenState();
}

class _AddWishScreenState extends State<AddWishScreen> {
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
  final ImageCacheService _imageCacheService = ImageCacheService();

  // Form state
  File? _selectedImage;
  String? _scrapedImageUrl;
  String _currency = 'USD';
  bool _isLoading = false;
  bool _isCompressingImage = false;
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

    // Auto-focus title field after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _titleFocusNode.requestFocus();
      }
    });

    // Listen for title changes to enable/disable save button
    _titleController.addListener(() {
      setState(() {});
    });

    // Listen for URL changes with debouncing
    _urlController.addListener(_onUrlChanged);

    // Pre-fill data if provided (from feed copy)
    if (widget.prefilledData != null) {
      final data = widget.prefilledData!;
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _priceController.text = data['price']?.toString() ?? '';
      _urlController.text = data['url'] ?? '';
      _currency = data['currency'] ?? 'USD';
      _scrapedImageUrl = data['image'];

      // Auto-show fields with data
      if (data['description'] != null && data['description'].toString().isNotEmpty) {
        _visibleFields.add('description');
      }
      if (data['url'] != null && data['url'].toString().isNotEmpty) {
        _visibleFields.add('url');
      }
      if (data['price'] != null) {
        _visibleFields.add('price');
      }
      if (data['image'] != null) {
        _visibleFields.add('image');
      }
    }
    // Otherwise pre-fill URL if provided from clipboard
    else if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
      _visibleFields.add('url');
      // Trigger scraping after a short delay to allow UI to settle
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _scrapeUrl(widget.initialUrl!);
        }
      });
    }

    // Pre-select wishlist if provided, or select first available wishlist
    _selectedWishlistId = widget.wishlistId;

    // Auto-select first wishlist after a short delay if none is pre-selected
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _selectedWishlistId == null) {
        final wishlistService = context.read<WishlistService>();
        if (wishlistService.wishlists.isNotEmpty) {
          setState(() {
            _selectedWishlistId = wishlistService.wishlists.first.id;
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

  /// Paste URL from clipboard
  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();

      if (text != null && text.isNotEmpty) {
        _urlController.text = text;

        // Show URL field if not visible
        if (!_visibleFields.contains('url')) {
          setState(() {
            _visibleFields.add('url');
          });
          // Request focus after adding field
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _urlFocusNode.requestFocus();
            }
          });
        }

        // Trigger scraping if it's a valid URL
        if (_isValidUrl(text)) {
          _scrapeUrl(text);
        }

        // Show feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.content_paste, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('Link pasted'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error pasting from clipboard: $e');
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
        debugPrint('URL scraping failed: ${response.error}');
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
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Use camera',
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
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Select from photos',
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
      final XFile? image = await _imagePicker.pickImage(
        source: source,
      );

      if (image != null && mounted) {
        setState(() {
          _isCompressingImage = true;
        });

        final compressedImage = await _imageCacheService.compressAndCacheImage(
          imageFile: File(image.path),
          quality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        if (compressedImage != null && mounted) {
          setState(() {
            _selectedImage = compressedImage;
            _isCompressingImage = false;
            _visibleFields.add('image');
          });
        } else if (mounted) {
          setState(() {
            _selectedImage = File(image.path);
            _isCompressingImage = false;
            _visibleFields.add('image');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompressingImage = false;
        });
        _showPermissionDeniedDialog();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera/Photo Access Required'),
        content: const Text(
          'Jinnie needs access to your camera and photo library to add images to your items.',
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
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWish() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorMessage('wish.title_required'.tr());
      return;
    }

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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field - Always visible, big and borderless
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildBorderlessTextField(
                          controller: _titleController,
                          focusNode: _titleFocusNode,
                          hintText: 'wish.title_placeholder'.tr(),
                          fontSize: 28,
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
                          child: _buildBorderlessTextField(
                            controller: _descriptionController,
                            focusNode: _descriptionFocusNode,
                            hintText: 'Description',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _visibleFields.remove('description');
                              _descriptionController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.close,
                              size: 24,
                              color: Colors.grey[400],
                            ),
                          ),
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
                          child: _buildBorderlessTextField(
                            controller: _urlController,
                            focusNode: _urlFocusNode,
                            hintText: 'Link',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            keyboardType: TextInputType.url,
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
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _visibleFields.remove('url');
                                _urlController.clear();
                                _scrapedImageUrl = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.close,
                                size: 24,
                                color: Colors.grey[400],
                              ),
                            ),
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
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _visibleFields.remove('image');
                                _selectedImage = null;
                                _scrapedImageUrl = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.close,
                                size: 24,
                                color: Colors.grey[400],
                              ),
                            ),
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
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildBorderlessTextField(
                                  controller: _priceController,
                                  focusNode: _priceFocusNode,
                                  hintText: 'Price',
                                  fontSize: 20,
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
                                        fontSize: 18,
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
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _visibleFields.remove('price');
                              _priceController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.close,
                              size: 24,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Add More Details buttons
                  const SizedBox(height: 20),
                  _buildAddFieldButtons(),

                  // Wishlist Selector - Always visible at bottom
                  const SizedBox(height: 16),
                  Text(
                    'List',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildWishlistSelector(),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + 12),
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
                        children: [
                          Icon(Icons.content_paste, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Paste\nLink',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.2,
                              color: AppTheme.primary,
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

  Widget _buildBorderlessTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hintText,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
  }) {
    return Material(
      color: Colors.transparent,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: AppTheme.primary,
          height: 1.3, // Allow proper line height for multi-line text
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: Colors.grey[400],
            height: 1.3,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        maxLines: maxLines,
        minLines: 1,
        textCapitalization: textCapitalization,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildAddFieldButtons() {
    final availableFields = [
      if (!_visibleFields.contains('description')) {'key': 'description', 'label': 'Description', 'icon': Icons.notes, 'focusNode': _descriptionFocusNode},
      if (!_visibleFields.contains('url')) {'key': 'url', 'label': 'Link', 'icon': Icons.link, 'focusNode': _urlFocusNode},
      if (!_visibleFields.contains('image')) {'key': 'image', 'label': 'Photo', 'icon': Icons.image},
      if (!_visibleFields.contains('price')) {'key': 'price', 'label': 'Price', 'icon': Icons.attach_money, 'focusNode': _priceFocusNode},
    ];

    if (availableFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableFields.map((field) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _visibleFields.add(field['key'] as String);
            });

            // Request focus or perform action after setState
            Future.delayed(const Duration(milliseconds: 100), () {
              if (field['key'] == 'image') {
                _pickImage();
              } else if (field['focusNode'] != null) {
                (field['focusNode'] as FocusNode).requestFocus();
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  field['icon'] as IconData,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  field['label'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
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
                  ? Image.network(
                      _scrapedImageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                        );
                      },
                    )
                  : const SizedBox(),
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _isCompressingImage ? null : _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
        ),
        child: Center(
          child: _isCompressingImage
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Column(
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

  Widget _buildWishlistSelector() {
    final wishlistService = context.watch<WishlistService>();
    final wishlists = wishlistService.wishlists;

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wishlists.length + 1, // +1 for "New List" button
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          // Last item is "New List" button
          if (index == wishlists.length) {
            return GestureDetector(
              onTap: _createNewWishlist,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'New List',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final wishlist = wishlists[index];
          final isSelected = _selectedWishlistId == wishlist.id;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedWishlistId = wishlist.id;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryAccent : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  wishlist.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createNewWishlist() async {
    // Show create new wishlist bottom sheet
    final newWishlistId = await WishlistNewScreen.show(context);

    if (newWishlistId != null && newWishlistId is String && mounted) {
      // Refresh wishlists
      await context.read<WishlistService>().fetchWishlists();

      // Select the newly created wishlist
      setState(() {
        _selectedWishlistId = newWishlistId;
      });
    }
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

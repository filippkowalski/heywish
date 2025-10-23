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
import '../../models/wish.dart';
import '../../common/navigation/native_page_route.dart';
import '../../widgets/cached_image.dart';
import '../../common/utils/wish_category_detector.dart';
import 'wishlist_new_screen.dart';

class EditWishScreen extends StatefulWidget {
  final String wishId;
  final String wishlistId;

  const EditWishScreen({
    super.key,
    required this.wishId,
    required this.wishlistId,
  });

  /// Show as bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    required String wishId,
    required String wishlistId,
  }) {
    return NativeTransitions.showNativeModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      child: EditWishScreen(
        wishId: wishId,
        wishlistId: wishlistId,
      ),
    );
  }

  @override
  State<EditWishScreen> createState() => _EditWishScreenState();
}

class _EditWishScreenState extends State<EditWishScreen> {
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
  String? _existingImageUrl;
  String _currency = 'USD';
  bool _isLoading = false;
  bool _isCompressingImage = false;
  String? _selectedWishlistId;
  Wish? _wish;

  // Visible fields tracking
  final Set<String> _visibleFields = {};

  // Currency list will be populated in initState based on user locale
  List<String> _currencies = [];

  @override
  void initState() {
    super.initState();

    // Initialize currencies based on user locale
    _initializeCurrencies();

    // Load existing wish data
    _loadWish();

    // Listen for title changes to enable/disable save button
    _titleController.addListener(() {
      setState(() {});
    });
  }

  void _initializeCurrencies() {
    // Common currencies
    _currencies = [
      'USD', // US Dollar
      'EUR', // Euro
      'GBP', // British Pound
      'JPY', // Japanese Yen
      'CNY', // Chinese Yuan
      'AUD', // Australian Dollar
      'CAD', // Canadian Dollar
      'CHF', // Swiss Franc
      'INR', // Indian Rupee
      'MXN', // Mexican Peso
      'BRL', // Brazilian Real
      'KRW', // South Korean Won
      'SEK', // Swedish Krona
      'NOK', // Norwegian Krone
      'DKK', // Danish Krone
      'PLN', // Polish Zloty
      'THB', // Thai Baht
      'SGD', // Singapore Dollar
      'HKD', // Hong Kong Dollar
      'NZD', // New Zealand Dollar
    ];
  }

  void _loadWish() {
    final wishlistService = context.read<WishlistService>();
    _wish = wishlistService.findWishById(widget.wishId);

    if (_wish != null) {
      // Prefill all fields with existing data
      _titleController.text = _wish!.title;
      _descriptionController.text = _wish!.description ?? '';
      _priceController.text = _wish!.price?.toString() ?? '';
      _urlController.text = _wish!.url ?? '';
      _currency = _wish!.currency ?? 'USD';
      _existingImageUrl = _wish!.imageUrl;
      _selectedWishlistId = _wish!.wishlistId;

      // Show fields that have data
      if (_wish!.description != null && _wish!.description!.isNotEmpty) {
        _visibleFields.add('description');
      }
      if (_wish!.price != null) {
        _visibleFields.add('price');
      }
      if (_wish!.url != null && _wish!.url!.isNotEmpty) {
        _visibleFields.add('url');
      }
      if (_wish!.imageUrl != null) {
        _visibleFields.add('image');
      }

      setState(() {});
    }
  }

  @override
  void dispose() {
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

  Future<void> _pickImage() async {
    try {
      final permissionStatus = await Permission.photos.request();

      if (!permissionStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('wish.photo_library_access_required'.tr()),
            ),
          );
        }
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (image != null && mounted) {
        setState(() {
          _isCompressingImage = true;
        });

        final compressedFile = await _imageCacheService.compressAndCacheImage(
          imageFile: File(image.path),
          quality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        setState(() {
          _selectedImage = compressedFile;
          _existingImageUrl = null; // Clear existing image URL when new image selected
          _scrapedImageUrl = null;
          _isCompressingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCompressingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('wish.failed_to_pick_image'.tr(namedArgs: {'error': e.toString()}))),
        );
      }
    }
  }

  Future<void> _updateWish() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('wish.please_enter_title'.tr())),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = context.read<ApiService>();
      List<String>? images;

      // Handle image upload
      if (_selectedImage != null) {
        final imageUrl = await apiService.uploadWishImage(imageFile: _selectedImage!);
        if (imageUrl != null) {
          images = [imageUrl];
        }
      } else if (_existingImageUrl != null) {
        // Keep existing image
        images = [_existingImageUrl!];
      } else if (_scrapedImageUrl != null) {
        images = [_scrapedImageUrl!];
      }

      final price = _priceController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceController.text.trim());

      await context.read<WishlistService>().updateWish(
            widget.wishId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            price: price,
            currency: _currency,
            url: _urlController.text.trim().isEmpty
                ? null
                : _urlController.text.trim(),
            images: images,
          );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success

        // Show success snackbar after navigation
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('wish.item_updated'.tr()),
                backgroundColor: AppTheme.primaryAccent,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('wish.failed_to_update'.tr(namedArgs: {'error': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    if (_wish == null) {
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
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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
                              fontSize: 17,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              keyboardType: TextInputType.url,
                              textColor: Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _visibleFields.remove('url');
                                _urlController.clear();
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
                              child: (_selectedImage != null || _existingImageUrl != null || _scrapedImageUrl != null)
                                  ? _buildImagePreview()
                                  : _buildAddImageButton(),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _visibleFields.remove('image');
                                  _selectedImage = null;
                                  _existingImageUrl = null;
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
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: (_isLoading || _titleController.text.trim().isEmpty) ? null : _updateWish,
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
                      : const Text(
                          'Update',
                          style: TextStyle(
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
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor ?? AppTheme.primary,
          height: 1.3,
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
              : _existingImageUrl != null
                  ? CachedImageWidget(
                      imageUrl: _existingImageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: Center(
                        child: Icon(
                          WishCategoryDetector.getIconFromTitle(_titleController.text),
                          size: 48,
                          color: WishCategoryDetector.getColorFromTitle(_titleController.text),
                        ),
                      ),
                    )
                  : _scrapedImageUrl != null
                      ? CachedImageWidget(
                          imageUrl: _scrapedImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: Center(
                            child: Icon(
                              WishCategoryDetector.getIconFromTitle(_titleController.text),
                              size: 48,
                              color: WishCategoryDetector.getColorFromTitle(_titleController.text),
                            ),
                          ),
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
}

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
            const SnackBar(
              content: Text('Photo library access is required to add images'),
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

        final compressedFile = await _imageCacheService.compressImage(
          File(image.path),
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
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _updateWish() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
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
        final imageUrl = await apiService.uploadImage(_selectedImage!);
        images = [imageUrl];
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
                content: const Text('Item updated successfully'),
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
            content: Text('Failed to update item: $e'),
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
            // Header with handle bar
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Edit Item',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Item name',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primary,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 20),

                    // Visible fields
                    ..._buildVisibleFields(),

                    const SizedBox(height: 12),

                    // Add field buttons
                    if (_visibleFields.length < 4) ..._buildAddFieldButtons(),

                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: (_isLoading || _titleController.text.trim().isEmpty)
                            ? null
                            : _updateWish,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryAccent,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildVisibleFields() {
    final fields = <Widget>[];

    for (final fieldKey in _visibleFields) {
      Widget? field;

      switch (fieldKey) {
        case 'description':
          field = _buildDescriptionField();
          break;
        case 'price':
          field = _buildPriceField();
          break;
        case 'url':
          field = _buildUrlField();
          break;
        case 'image':
          field = _buildImageField();
          break;
      }

      if (field != null) {
        fields.add(field);
        fields.add(const SizedBox(height: 16));
      }
    }

    return fields;
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.description_outlined, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _priceController,
              focusNode: _priceFocusNode,
              decoration: InputDecoration(
                hintText: 'Price',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _currency,
            underline: const SizedBox(),
            isDense: true,
            items: _currencies.map((currency) {
              return DropdownMenuItem(
                value: currency,
                child: Text(
                  currency,
                  style: const TextStyle(fontSize: 14),
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
    );
  }

  Widget _buildUrlField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.link, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _urlController,
              focusNode: _urlFocusNode,
              decoration: InputDecoration(
                hintText: 'URL',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
              keyboardType: TextInputType.url,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageField() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _isCompressingImage
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Compressing image...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              )
            : _selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                : _existingImageUrl != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: CachedImageWidget(
                              imageUrl: _existingImageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: Center(
                                child: Icon(
                                  WishCategoryDetector.getIconFromTitle(_titleController.text),
                                  size: 48,
                                  color: WishCategoryDetector.getColorFromTitle(_titleController.text),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _existingImageUrl = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : _scrapedImageUrl != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: CachedImageWidget(
                                  imageUrl: _scrapedImageUrl!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorWidget: Center(
                                    child: Icon(
                                      WishCategoryDetector.getIconFromTitle(_titleController.text),
                                      size: 48,
                                      color: WishCategoryDetector.getColorFromTitle(_titleController.text),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _scrapedImageUrl = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add image',
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

  List<Widget> _buildAddFieldButtons() {
    final availableFields = [
      if (!_visibleFields.contains('description'))
        {
          'key': 'description',
          'icon': Icons.description_outlined,
          'label': 'Description',
          'focusNode': _descriptionFocusNode,
        },
      if (!_visibleFields.contains('price'))
        {
          'key': 'price',
          'icon': Icons.attach_money,
          'label': 'Price',
          'focusNode': _priceFocusNode,
        },
      if (!_visibleFields.contains('url'))
        {
          'key': 'url',
          'icon': Icons.link,
          'label': 'URL',
          'focusNode': _urlFocusNode,
        },
      if (!_visibleFields.contains('image'))
        {
          'key': 'image',
          'icon': Icons.image_outlined,
          'label': 'Image',
        },
    ];

    return availableFields.map((field) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _visibleFields.add(field['key'] as String);
            });
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
              children: [
                Icon(field['icon'] as IconData, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  field['label'] as String,
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
    }).toList();
  }
}

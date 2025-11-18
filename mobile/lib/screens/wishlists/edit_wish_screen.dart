import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import '../../services/wishlist_service.dart';
import '../../services/image_cache_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../models/wish.dart';
import '../../common/navigation/native_page_route.dart';
import '../../widgets/cached_image.dart';
import '../../common/utils/wish_category_detector.dart';
import 'widgets/wish_form_widgets.dart';

class EditWishScreen extends StatefulWidget {
  final String wishId;
  final String? wishlistId; // Nullable for unsorted wishes

  const EditWishScreen({
    super.key,
    required this.wishId,
    this.wishlistId, // Optional for unsorted wishes
  });

  /// Show as bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    required String wishId,
    String? wishlistId, // Optional for unsorted wishes
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
            wishlistId: _selectedWishlistId,
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
                            autofocus: _titleController.text.isEmpty,
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
                          WishFieldCloseButton(
                            onTap: () {
                              setState(() {
                                _visibleFields.remove('url');
                                _urlController.clear();
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
                              child: (_selectedImage != null || _existingImageUrl != null || _scrapedImageUrl != null)
                                  ? _buildImagePreview()
                                  : _buildAddImageButton(),
                            ),
                            WishFieldCloseButton(
                              onTap: () {
                                setState(() {
                                  _visibleFields.remove('image');
                                  _selectedImage = null;
                                  _existingImageUrl = null;
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

            // Bottom button
            Container(
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                bottomPadding > 0 ? bottomPadding + 16 : mediaQuery.padding.bottom + 16,
              ),
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
        height: 140,
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

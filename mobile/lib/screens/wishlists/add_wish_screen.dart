import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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

  @override
  State<AddWishScreen> createState() => _AddWishScreenState();
}

class _AddWishScreenState extends State<AddWishScreen> {
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _urlController = TextEditingController();

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

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'];

  @override
  void initState() {
    super.initState();

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
    }
    // Otherwise pre-fill URL if provided from clipboard
    else if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
      // Trigger scraping after a short delay to allow UI to settle
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _scrapeUrl(widget.initialUrl!);
        }
      });
    }

    // Pre-select wishlist if provided
    _selectedWishlistId = widget.wishlistId;
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    super.dispose();
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
                  const Text('Pasted from clipboard'),
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
    if (_isScrapingUrl) return; // Prevent multiple concurrent scrapes

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

        // Auto-fill title if empty or user hasn't modified it
        if (_titleController.text.isEmpty && metadata.title != null) {
          _titleController.text = metadata.title!;
        }

        // Auto-fill description if available
        if (_descriptionController.text.isEmpty && metadata.description != null) {
          _descriptionController.text = metadata.description!;
        }

        // Auto-fill price if available
        if (_priceController.text.isEmpty && metadata.price != null) {
          _priceController.text = metadata.price!.toStringAsFixed(2);
          if (metadata.currency != null) {
            _currency = metadata.currency!;
          }
        }

        // Store scraped image URL (we'll use this if user hasn't selected an image)
        if (metadata.image != null) {
          _scrapedImageUrl = metadata.image;
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
        // Silent fail - don't show error for scraping failures
        debugPrint('URL scraping failed: ${response.error}');
      }
    } catch (e) {
      debugPrint('Error scraping URL: $e');
      // Silent fail - don't interrupt user experience
    } finally {
      if (mounted) {
        setState(() {
          _isScrapingUrl = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null && mounted) {
        setState(() {
          _isCompressingImage = true;
        });

        // Compress and cache the image
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
          });
        } else if (mounted) {
          setState(() {
            _selectedImage = File(image.path);
            _isCompressingImage = false;
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
        title: const Text('Photo Library Access Required'),
        content: const Text(
          'HeyWish needs access to your photo library to select images for your items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      _showErrorMessage('wish.title_required'.tr());
      return;
    }

    // Wishlist selection is now optional - uncategorized wishes are supported
    setState(() {
      _isLoading = true;
    });

    try {
      final price = _priceController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceController.text.trim());

      // Add wish with optional wishlistId
      await context.read<WishlistService>().addWish(
        wishlistId: _selectedWishlistId, // Can be null for uncategorized wishes
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
      );

      if (mounted) {
        // Show success message before popping
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('wish.created_successfully'.tr()),
            backgroundColor: AppTheme.primaryAccent,
            duration: const Duration(seconds: 2),
          ),
        );

        // Pop after a brief delay to allow SnackBar to show
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            context.pop();
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.primary),
          onPressed: () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'wish.add_item'.tr(),
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveWish,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 32),
            _buildImageSection(),
            const SizedBox(height: 32),
            _buildWishlistSelectorSection(),
            const SizedBox(height: 32),
            _buildPriceSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistSelectorSection() {
    final wishlistService = context.watch<WishlistService>();
    final wishlists = wishlistService.wishlists;

    Wishlist? selectedWishlist;
    if (_selectedWishlistId != null && wishlists.isNotEmpty) {
      try {
        selectedWishlist = wishlists.firstWhere((w) => w.id == _selectedWishlistId);
      } catch (e) {
        selectedWishlist = null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wish.select_wishlist'.tr(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'wish.select_wishlist_desc'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () async {
            // Show wishlist selector or create new
            final result = await _showWishlistSelectionBottomSheet();
            if (result != null) {
              setState(() {
                _selectedWishlistId = result;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.list_alt_outlined,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedWishlist != null
                        ? selectedWishlist.name
                        : 'wish.select_wishlist_placeholder'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedWishlist != null
                          ? AppTheme.primary
                          : Colors.grey.shade500,
                      fontWeight: selectedWishlist != null
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _showWishlistSelectionBottomSheet() async {
    final wishlistService = context.read<WishlistService>();
    await wishlistService.fetchWishlists();
    final wishlists = wishlistService.wishlists;

    if (!mounted) return null;

    return showModalBottomSheet<String>(
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Choose where to save this item',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                // Create new wishlist button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await context.push('/wishlists/new');
                        if (result != null && result is String) {
                          setState(() {
                            _selectedWishlistId = result;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryAccent,
                                    AppTheme.primaryAccent.withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'wishlist.create_new'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Start a new collection',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (wishlists.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Text(
                      'YOUR WISHLISTS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                  // Wishlist list
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
                                color: isSelected ? AppTheme.primaryAccent.withValues(alpha: 0.08) : Colors.grey[50],
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
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryAccent.withValues(alpha: 0.15)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: wishlist.coverImageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                              wishlist.coverImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.card_giftcard_rounded,
                                                color: isSelected ? AppTheme.primaryAccent : Colors.grey[400],
                                                size: 22,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.card_giftcard_rounded,
                                            color: isSelected ? AppTheme.primaryAccent : Colors.grey[400],
                                            size: 22,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          wishlist.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? AppTheme.primaryAccent : AppTheme.primary,
                                          ),
                                        ),
                                        if (wishlist.description != null && wishlist.description!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              wishlist.description!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${wishlist.wishCount} items',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Edit button
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      context.push('/wishlists/${wishlist.id}/edit');
                                    },
                                    tooltip: 'app.edit'.tr(),
                                  ),
                                  const SizedBox(width: 4),
                                  if (isSelected)
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wish.basic_information'.tr(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'wish.basic_information_desc'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'wish.item_title'.tr() + ' *',
            hintText: 'wish.title_placeholder'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.edit_outlined),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _descriptionController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'wish.item_description'.tr(),
            hintText: 'wish.description_placeholder'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.description_outlined),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'wish.url'.tr(),
            hintText: 'https://example.com/product',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.link_outlined),
            suffixIcon: _isScrapingUrl
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _urlController.text.isNotEmpty && _isValidUrl(_urlController.text)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : IconButton(
                        icon: const Icon(Icons.content_paste),
                        tooltip: 'Paste from clipboard',
                        onPressed: _pasteFromClipboard,
                      ),
            helperText: _isScrapingUrl
                ? '✨ Loading product details...'
                : (_urlController.text.isEmpty
                    ? 'Tap paste icon to paste from clipboard'
                    : null),
            helperMaxLines: 1,
          ),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wish.image_section'.tr(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'wish.image_section_desc'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 24),
        (_selectedImage != null || _scrapedImageUrl != null)
            ? _buildSelectedImage()
            : _buildAddImageButton(),
      ],
    );
  }

  Widget _buildSelectedImage() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
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
                    width: double.infinity,
                    height: 200,
                  )
                : _scrapedImageUrl != null
                    ? Image.network(
                        _scrapedImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : const SizedBox(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Change Image'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _scrapedImageUrl = null;
                });
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(100, 48),
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade300),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return OutlinedButton.icon(
      onPressed: _isCompressingImage ? null : _pickImage,
      icon: _isCompressingImage
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.image_outlined),
      label: Text(
        _isCompressingImage ? 'Processing...' : 'wish.add_image'.tr(),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 120),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wish.price_section'.tr(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'wish.price_section_desc'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'wish.price'.tr(),
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _currency,
                decoration: InputDecoration(
                  labelText: 'wish.currency'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _currency = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final bool isDisabled = _isLoading || _isCompressingImage;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isDisabled ? null : _saveWish,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isDisabled
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_isCompressingImage ? 'Processing image...' : 'Saving...'),
                ],
              )
            : const Text('Save Item'),
      ),
    );
  }
}

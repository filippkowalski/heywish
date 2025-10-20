import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../services/wishlist_service.dart';
import '../../services/image_cache_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../common/navigation/native_page_route.dart';

class WishlistNewScreen extends StatefulWidget {
  const WishlistNewScreen({super.key});

  /// Show as bottom sheet
  static Future<String?> show(BuildContext context) {
    return NativeTransitions.showNativeModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      child: const WishlistNewScreen(),
    );
  }

  @override
  State<WishlistNewScreen> createState() => _WishlistNewScreenState();
}

class _WishlistNewScreenState extends State<WishlistNewScreen> {
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Focus nodes
  final _nameFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  final ImageCacheService _imageCacheService = ImageCacheService();

  // Form state
  String _selectedVisibility = 'private';
  File? _selectedHeaderImage;
  bool _isLoading = false;
  bool _isCompressingImage = false;

  // Visible fields tracking
  final Set<String> _visibleFields = {};

  @override
  void initState() {
    super.initState();

    // Auto-focus name field after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });

    // Listen for name changes to enable/disable create button
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _createWishlist() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showErrorMessage('wishlist.name_required'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? coverImageUrl;

      // Upload header image if selected
      if (_selectedHeaderImage != null) {
        final apiService = context.read<ApiService>();
        coverImageUrl = await apiService.uploadWishlistCoverImage(
          imageFile: _selectedHeaderImage!,
        );

        if (coverImageUrl == null && mounted) {
          _showErrorMessage('Failed to upload cover image');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Create wishlist with cover image URL
      final wishlist = await context.read<WishlistService>().createWishlist(
            name: name,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            visibility: _selectedVisibility,
            coverImageUrl: coverImageUrl,
          );

      if (wishlist != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('List created successfully!'),
            backgroundColor: AppTheme.primaryAccent,
            duration: const Duration(seconds: 2),
          ),
        );

        // Return the wishlist ID so it can be used by the caller
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.of(context).pop(wishlist.id);
          }
        });
      } else if (mounted) {
        _showErrorMessage('wishlist.create_failed'.tr());
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString());
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

    return Container(
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
                  // Name field - Always visible, big and borderless
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildBorderlessTextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          hintText: 'List Name',
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

                  // Header Image Field (if visible)
                  if (_visibleFields.contains('image')) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _selectedHeaderImage != null
                                ? _buildImagePreview()
                                : _buildAddImageButton(),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _visibleFields.remove('image');
                                _selectedHeaderImage = null;
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

                  // Add More Details buttons
                  const SizedBox(height: 20),
                  _buildAddFieldButtons(),

                  // Privacy/Visibility Selector - Always visible at bottom
                  const SizedBox(height: 16),
                  Text(
                    'List visibility',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildVisibilitySelector(),
                ],
              ),
            ),
          ),

          // Bottom button
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
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
                onPressed: (_isLoading || _nameController.text.trim().isEmpty) ? null : _createWishlist,
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
                        'Create List',
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
  }) {
    return TextField(
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
    );
  }

  Widget _buildVisibilitySelector() {
    final visibilityOptions = [
      {'value': 'private', 'label': 'Private', 'icon': Icons.lock_outlined},
      {'value': 'friends', 'label': 'Friends', 'icon': Icons.people_outlined},
      {'value': 'public', 'label': 'Public', 'icon': Icons.public_outlined},
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibilityOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = visibilityOptions[index];
          final isSelected = _selectedVisibility == option['value'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedVisibility = option['value'] as String;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryAccent : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      option['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddFieldButtons() {
    final availableFields = [
      if (!_visibleFields.contains('description')) {'key': 'description', 'label': 'Description', 'icon': Icons.notes, 'focusNode': _descriptionFocusNode},
      if (!_visibleFields.contains('image')) {'key': 'image', 'label': 'Cover Image', 'icon': Icons.image},
    ];

    if (availableFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableFields.map((field) {
        return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _visibleFields.add(field['key'] as String);
            });

            // Request focus or perform action after setState
            Future.delayed(const Duration(milliseconds: 100), () {
              if (field['key'] == 'image') {
                _pickHeaderImage();
              } else if (field['focusNode'] != null) {
                (field['focusNode'] as FocusNode).requestFocus();
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
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
      onTap: _pickHeaderImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _selectedHeaderImage != null
              ? Image.file(
                  _selectedHeaderImage!,
                  fit: BoxFit.cover,
                )
              : const SizedBox(),
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _isCompressingImage ? null : _pickHeaderImage,
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
                      'Tap to add cover image',
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

  Future<void> _pickHeaderImage() async {
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
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (compressedImage != null && mounted) {
          setState(() {
            _selectedHeaderImage = compressedImage;
            _isCompressingImage = false;
            _visibleFields.add('image');
          });
        } else if (mounted) {
          setState(() {
            _selectedHeaderImage = File(image.path);
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
          'Jinnie needs access to your camera and photo library to add cover images for your lists.',
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
}

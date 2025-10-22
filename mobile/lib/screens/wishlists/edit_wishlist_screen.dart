import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../models/wishlist.dart';
import '../../services/wishlist_service.dart';
import '../../services/image_cache_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class EditWishlistScreen extends StatefulWidget {
  final String wishlistId;

  const EditWishlistScreen({
    super.key,
    required this.wishlistId,
  });

  @override
  State<EditWishlistScreen> createState() => _EditWishlistScreenState();
}

class _EditWishlistScreenState extends State<EditWishlistScreen> {
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  final ImageCacheService _imageCacheService = ImageCacheService();

  // Form state
  String _selectedVisibility = 'private';
  File? _selectedHeaderImage;
  String? _existingCoverImageUrl;
  bool _isLoading = false;
  bool _isCompressingImage = false;
  bool _coverImageChanged = false;
  Wishlist? _wishlist;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadWishlist() {
    final wishlistService = context.read<WishlistService>();
    _wishlist = wishlistService.getCachedWishlist(widget.wishlistId);

    if (_wishlist != null) {
      _titleController.text = _wishlist!.name;
      _descriptionController.text = _wishlist!.description ?? '';
      _selectedVisibility = _wishlist!.visibility;
      _existingCoverImageUrl = _wishlist!.coverImageUrl;
      setState(() {});
    }
  }

  Future<void> _saveWishlist() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showErrorMessage('wishlist.name_required'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? coverImageUrl = _existingCoverImageUrl;

      // Upload new header image if changed
      if (_coverImageChanged && _selectedHeaderImage != null) {
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
      } else if (_coverImageChanged && _selectedHeaderImage == null) {
        // User removed the image
        coverImageUrl = null;
      }

      // Update wishlist via API service directly to handle null coverImageUrl
      if (_coverImageChanged) {
        final apiService = context.read<ApiService>();
        await apiService.patch('/wishlists/${widget.wishlistId}', {
          'name': title,
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'visibility': _selectedVisibility,
          'coverImageUrl': coverImageUrl, // Can be null to remove
        });
      } else {
        // No image change, use regular update
        await context.read<ApiService>().patch('/wishlists/${widget.wishlistId}', {
          'name': title,
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'visibility': _selectedVisibility,
        });
      }

      // Refresh wishlist data
      final wishlistService = context.read<WishlistService>();
      await wishlistService.fetchWishlists();

      final success = true;

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('wishlist.updated_successfully'.tr()),
            backgroundColor: AppTheme.primaryAccent,
          ),
        );
        context.pop();
      } else if (mounted) {
        _showErrorMessage('Failed to update wishlist');
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

  Future<void> _pickHeaderImage() async {
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
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (compressedImage != null && mounted) {
          setState(() {
            _selectedHeaderImage = compressedImage;
            _coverImageChanged = true;
            _isCompressingImage = false;
          });
        } else if (mounted) {
          setState(() {
            _selectedHeaderImage = File(image.path);
            _coverImageChanged = true;
            _isCompressingImage = false;
          });
          _showErrorMessage('Image compression failed, using original');
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

  void _removeHeaderImage() {
    setState(() {
      _selectedHeaderImage = null;
      _existingCoverImageUrl = null;
      _coverImageChanged = true;
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Library Access Required'),
        content: const Text(
          'Jinnie needs access to your photo library to select header images for your wishlists. Please grant permission in Settings.',
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Wishlist',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 32),
            _buildHeaderImageSection(),
            const SizedBox(height: 32),
            _buildPrivacySection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wishlist.basic_information'.tr(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'wishlist.basic_information_desc'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'wishlist.name'.tr(),
            hintText: 'wishlist.name_placeholder'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.edit_outlined),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _descriptionController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'wishlist.description'.tr(),
            hintText: 'wishlist.description_placeholder'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.description_outlined),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildHeaderImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wishlist.header_image'.tr(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'wishlist.header_image_desc'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 24),
        _selectedHeaderImage != null || _existingCoverImageUrl != null
            ? _buildSelectedHeaderImage()
            : _buildAddHeaderImageButton(),
      ],
    );
  }

  Widget _buildSelectedHeaderImage() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
            image: _selectedHeaderImage != null
                ? DecorationImage(
                    image: FileImage(_selectedHeaderImage!),
                    fit: BoxFit.cover,
                  )
                : (_existingCoverImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_existingCoverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickHeaderImage,
                icon: const Icon(Icons.edit_outlined),
                label: Text('wishlist.change_header_image'.tr()),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _removeHeaderImage,
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

  Widget _buildAddHeaderImageButton() {
    return OutlinedButton.icon(
      onPressed: _isCompressingImage ? null : _pickHeaderImage,
      icon: _isCompressingImage
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.image_outlined),
      label: Text(
        _isCompressingImage
            ? 'Processing...'
            : 'wishlist.add_header_image'.tr(),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 120),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wishlist.privacy_settings'.tr(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'wishlist.privacy_settings_desc'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 24),
        _buildVisibilityOption(
          'private',
          'wishlist.privacy_private'.tr(),
          'wishlist.privacy_private_desc'.tr(),
          Icons.lock_outlined,
        ),
        const SizedBox(height: 12),
        _buildVisibilityOption(
          'friends',
          'wishlist.privacy_friends'.tr(),
          'wishlist.privacy_friends_desc'.tr(),
          Icons.people_outlined,
        ),
        const SizedBox(height: 12),
        _buildVisibilityOption(
          'public',
          'wishlist.privacy_public'.tr(),
          'wishlist.privacy_public_desc'.tr(),
          Icons.public_outlined,
        ),
      ],
    );
  }

  Widget _buildVisibilityOption(
      String value, String title, String subtitle, IconData icon) {
    final isSelected = _selectedVisibility == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVisibility = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primary : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final bool isDisabled = _isLoading || _isCompressingImage;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isDisabled ? null : _saveWishlist,
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
            : const Text('Save Changes'),
      ),
    );
  }
}

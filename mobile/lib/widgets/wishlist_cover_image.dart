import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'cached_image.dart';

class WishlistCoverImage extends StatelessWidget {
  final String? coverImageUrl;
  final String wishlistId;
  final bool canEdit;
  final double height;
  final VoidCallback? onImageChanged;
  final Future<bool> Function(String, File)? onUpload;
  final Future<bool> Function(String)? onRemove;

  const WishlistCoverImage({
    super.key,
    this.coverImageUrl,
    required this.wishlistId,
    this.canEdit = true,
    this.height = 200,
    this.onImageChanged,
    this.onUpload,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Background image or placeholder
          _buildImageContent(),
          
          // Edit overlay
          if (canEdit)
            _buildEditOverlay(context),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (coverImageUrl != null && coverImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedImageWidget(
          imageUrl: coverImageUrl,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          placeholder: _buildPlaceholder(),
          errorWidget: _buildPlaceholder(),
        ),
      );
    }
    
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: height > 120 ? 32 : 24,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 6),
          Text(
            'Add Cover Photo',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: height > 120 ? 14 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditOverlay(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Row(
        children: [
          if (coverImageUrl != null && coverImageUrl!.isNotEmpty) ...[
            _buildActionButton(
              context,
              icon: Icons.delete_outline,
              onTap: () => _removeImage(context),
              color: Colors.red.shade600,
              backgroundColor: Colors.white,
            ),
            const SizedBox(width: 6),
          ],
          _buildActionButton(
            context,
            icon: Icons.camera_alt_outlined,
            onTap: () => _pickAndUploadImage(context),
            color: Colors.grey.shade700,
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Show image source selection
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Pick image
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Upload image
      final File imageFile = File(pickedFile.path);
      final success = await onUpload?.call(wishlistId, imageFile) ?? false;

      if (context.mounted) {
        Navigator.pop(context); // Remove loading dialog
        
        if (success) {
          onImageChanged?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cover image updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update cover image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Remove loading dialog if it's shown
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeImage(BuildContext context) async {
    // Confirm removal
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Cover Image'),
          content: const Text('Are you sure you want to remove the cover image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Remove image
      final success = await onRemove?.call(wishlistId) ?? false;

      if (context.mounted) {
        Navigator.pop(context); // Remove loading dialog
        
        if (success) {
          onImageChanged?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cover image removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove cover image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Remove loading dialog if it's shown
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
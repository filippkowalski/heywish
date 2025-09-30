import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_theme.dart';

class WishlistNewScreen extends StatefulWidget {
  const WishlistNewScreen({super.key});

  @override
  State<WishlistNewScreen> createState() => _WishlistNewScreenState();
}

class _WishlistNewScreenState extends State<WishlistNewScreen> {
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Form state
  String _selectedVisibility = 'private';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }


  Future<void> _createWishlist() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showErrorMessage('wishlist.name_required'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final wishlist = await context.read<WishlistService>().createWishlist(
            name: title,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            visibility: _selectedVisibility,
          );

      if (wishlist != null && mounted) {
        // Use pushReplacement to replace the create screen so back button works correctly
        context.pushReplacement('/wishlists/${wishlist.id}');
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
          'wishlist.create_new'.tr(),
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
            _buildPrivacySection(),
            const SizedBox(height: 32),
            _buildCreateButton(),
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
            color: AppTheme.primary.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _titleController,
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
            color: AppTheme.primary.withOpacity(0.7),
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

  Widget _buildVisibilityOption(String value, String title, String subtitle, IconData icon) {
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
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
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

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : _createWishlist,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Creating...'),
                ],
              )
            : Text('wishlist.create'.tr()),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/wishlist.dart';
import '../../services/wishlist_service.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedVisibility = 'private';
  bool _isLoading = false;
  Wishlist? _wishlist;

  final List<String> _visibilityOptions = ['private', 'public'];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadWishlist() {
    final wishlistService = context.read<WishlistService>();
    _wishlist = wishlistService.currentWishlist;
    
    if (_wishlist != null) {
      _nameController.text = _wishlist!.name;
      _descriptionController.text = _wishlist!.description ?? '';
      _selectedVisibility = _wishlist!.visibility;
      setState(() {});
    }
  }

  Future<void> _saveWishlist() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<WishlistService>().updateWishlist(
        widget.wishlistId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
        visibility: _selectedVisibility,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wishlist updated successfully!')),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update wishlist')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Wishlist'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveWishlist,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name Field
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Basic Information',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Wishlist Name',
                                hintText: 'e.g., Birthday Wishlist',
                                prefixIcon: Icon(Icons.list_alt),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a wishlist name';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description (Optional)',
                                hintText: 'Tell people about this wishlist...',
                                prefixIcon: Icon(Icons.description),
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Privacy Settings
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Privacy Settings',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: _visibilityOptions.map((option) {
                                return RadioListTile<String>(
                                  title: Text(option == 'private' ? 'Private' : 'Public'),
                                  subtitle: Text(
                                    option == 'private' 
                                        ? 'Only you can see this wishlist'
                                        : 'Anyone with the link can view this wishlist',
                                  ),
                                  value: option,
                                  groupValue: _selectedVisibility,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedVisibility = value!;
                                    });
                                  },
                                  activeColor: Theme.of(context).colorScheme.primary,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _saveWishlist,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.save),
                      label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cancel Button  
                    OutlinedButton(
                      onPressed: _isLoading ? null : () => context.pop(),
                      child: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
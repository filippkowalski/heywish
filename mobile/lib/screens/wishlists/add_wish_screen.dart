import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/wishlist_service.dart';
import '../../theme/app_theme.dart';

class AddWishScreen extends StatefulWidget {
  final String wishlistId;

  const AddWishScreen({
    super.key,
    required this.wishlistId,
  });

  @override
  State<AddWishScreen> createState() => _AddWishScreenState();
}

class _AddWishScreenState extends State<AddWishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String _currency = 'USD';
  int _priority = 1;
  int _quantity = 1;
  bool _isLoading = false;

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'];
  final List<int> _priorities = [1, 2, 3, 4, 5];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Image'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addWish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final price = _priceController.text.trim().isEmpty 
          ? null 
          : double.tryParse(_priceController.text.trim());

      await context.read<WishlistService>().addWish(
        wishlistId: widget.wishlistId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: price,
        currency: _currency,
        url: _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        priority: _priority.toString(),
        quantity: _quantity,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        imageFile: _selectedImage,
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Add Item'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _addWish,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showImageOptions,
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: AppTheme.gray100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.gray200,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _selectedImage != null
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
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: _showImageOptions,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: AppTheme.gray400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add Photo',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.gray600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'What would you like?',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add details about this item...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Price and Currency Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
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
              const SizedBox(height: 16),

              // URL
              TextFormField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Product URL',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),

              // Priority and Quantity Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Priority',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<int>(
                            value: _priority,
                            isExpanded: true,
                            underline: const SizedBox(),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            items: _priorities.map((priority) {
                              return DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    ...List.generate(
                                      priority,
                                      (index) => Icon(
                                        Icons.star,
                                        size: 16,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Priority $priority'),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _priority = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: _quantity > 1
                                    ? () {
                                        setState(() {
                                          _quantity--;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.remove),
                                iconSize: 20,
                              ),
                              Text(
                                '$_quantity',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _quantity++;
                                  });
                                },
                                icon: const Icon(Icons.add),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Any special notes or preferences...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _addWish,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Adding Item...'),
                          ],
                        )
                      : const Text('Add to Wishlist'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
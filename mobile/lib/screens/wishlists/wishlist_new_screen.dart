import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_theme.dart';

class WishlistNewScreen extends StatefulWidget {
  const WishlistNewScreen({super.key});

  @override
  State<WishlistNewScreen> createState() => _WishlistNewScreenState();
}

class _WishlistNewScreenState extends State<WishlistNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedOccasion;
  DateTime? _eventDate;
  bool _isPublic = false;
  bool _isLoading = false;

  final List<String> _occasions = [
    'Birthday',
    'Christmas',
    'Wedding',
    'Anniversary',
    'Baby Shower',
    'Graduation',
    'Housewarming',
    'Valentine\'s Day',
    'Mother\'s Day',
    'Father\'s Day',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createWishlist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final wishlist = await context.read<WishlistService>().createWishlist(
            name: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            occasionType: _selectedOccasion,
            eventDate: _eventDate,
            visibility: _isPublic ? 'public' : 'private',
          );

      if (wishlist != null && mounted) {
        context.go('/wishlists/${wishlist.id}');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create wishlist'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null && picked != _eventDate) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Wishlist'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Basic Information',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Wishlist Title *',
                            hintText: 'e.g., My Birthday Wishlist',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Add a description for your wishlist',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedOccasion,
                          decoration: const InputDecoration(
                            labelText: 'Occasion (Optional)',
                            prefixIcon: Icon(Icons.celebration),
                          ),
                          items: _occasions.map((occasion) {
                            return DropdownMenuItem(
                              value: occasion,
                              child: Text(occasion),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedOccasion = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Event Date (Optional)',
                              prefixIcon: Icon(Icons.calendar_today),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              _eventDate != null
                                  ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'
                                  : 'Select a date',
                              style: _eventDate != null
                                  ? Theme.of(context).textTheme.bodyLarge
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: AppTheme.gray400),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Settings',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Make Public'),
                          subtitle: const Text(
                            'Allow anyone with the link to view this wishlist',
                          ),
                          value: _isPublic,
                          onChanged: (value) {
                            setState(() {
                              _isPublic = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _createWishlist,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Create Wishlist'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          context.pop();
                        },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
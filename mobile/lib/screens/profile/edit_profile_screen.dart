import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/cached_image.dart';
import '../../theme/app_theme.dart';

enum UsernameCheckStatus {
  available,
  taken,
  checking,
  error,
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  String? _avatarUrl;

  // Username validation
  Timer? _debounceTimer;
  String? _usernameValidationError;
  UsernameCheckStatus? _usernameCheckResult;
  bool _isCheckingUsername = false;
  String? _originalUsername;
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to update button state when text changes
    _fullNameController.addListener(_updateButtonState);
    _bioController.addListener(_updateButtonState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load user data only once when the widget is first built
    if (!_hasLoadedInitialData) {
      _loadUserData();
      _hasLoadedInitialData = true;
    }
  }

  void _loadUserData() {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    if (user != null) {
      _fullNameController.text = user.name ?? '';
      _usernameController.text = user.username ?? '';
      _bioController.text = user.bio ?? '';
      _avatarUrl = user.avatarUrl;
      _originalUsername = user.username;
    }
  }

  void _updateButtonState() {
    setState(() {
      // Just trigger a rebuild to update _canSave
    });
  }

  /// Validate username according to Instagram-style rules
  String? _validateUsername(String username) {
    if (username.isEmpty) {
      return 'errors.validation_required'.tr();
    }

    if (username.length < 3) {
      return 'username_validation.min_length'.tr();
    }

    if (username.length > 30) {
      return 'username_validation.max_length'.tr();
    }

    // Check for spaces
    if (username.contains(' ')) {
      return 'username_validation.no_spaces'.tr();
    }

    // Check for invalid characters
    final validPattern = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!validPattern.hasMatch(username)) {
      return 'username_validation.invalid_characters'.tr();
    }

    // Cannot start or end with period
    if (username.startsWith('.') || username.endsWith('.')) {
      return 'username_validation.no_period_edges'.tr();
    }

    // Cannot have consecutive periods
    if (username.contains('..')) {
      return 'username_validation.no_consecutive_periods'.tr();
    }

    return null;
  }

  /// Clean and format username input
  String _cleanUsername(String input) {
    return input.replaceAll(' ', '').toLowerCase();
  }

  /// Get translated helper text based on username check result
  String? _getHelperText() {
    switch (_usernameCheckResult) {
      case UsernameCheckStatus.available:
        return 'username_validation.available'.tr();
      case UsernameCheckStatus.taken:
        return 'username_validation.taken'.tr();
      case UsernameCheckStatus.checking:
        return 'username_validation.checking'.tr();
      case UsernameCheckStatus.error:
        return 'username_validation.check_error'.tr();
      case null:
        return null;
    }
  }

  void _onUsernameChanged(String value) {
    final cleanedValue = _cleanUsername(value);

    // Update the text field if it was cleaned
    if (cleanedValue != value) {
      final cursorPosition = _usernameController.selection.baseOffset;
      _usernameController.value = TextEditingValue(
        text: cleanedValue,
        selection: TextSelection.collapsed(
          offset: cursorPosition > cleanedValue.length
              ? cleanedValue.length
              : cursorPosition,
        ),
      );
    }

    // Validate the username
    final validationError = _validateUsername(cleanedValue);
    setState(() {
      _usernameValidationError = validationError;
    });

    // Only check availability if username is valid and different from original
    _debounceTimer?.cancel();
    if (validationError == null &&
        cleanedValue.isNotEmpty &&
        cleanedValue != _originalUsername) {
      setState(() {
        _usernameCheckResult = UsernameCheckStatus.checking;
        _isCheckingUsername = true;
      });

      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _checkUsernameAvailability(cleanedValue);
      });
    } else if (cleanedValue == _originalUsername) {
      // If it's the original username, mark as available
      setState(() {
        _usernameCheckResult = UsernameCheckStatus.available;
        _isCheckingUsername = false;
      });
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    try {
      final apiService = ApiService();
      final response = await apiService.checkUsernameAvailability(username);

      if (response != null && mounted) {
        final isAvailable = response['available'] as bool;
        setState(() {
          _usernameCheckResult = isAvailable
              ? UsernameCheckStatus.available
              : UsernameCheckStatus.taken;
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameCheckResult = UsernameCheckStatus.error;
          _isCheckingUsername = false;
        });
      }
    }
  }

  Future<void> _cropImage(String imagePath) async {
    final theme = Theme.of(context);
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'profile.crop_avatar'.tr(),
          toolbarColor: theme.colorScheme.surface,
          toolbarWidgetColor: theme.colorScheme.onSurface,
          statusBarLight: theme.brightness == Brightness.light,
          backgroundColor: theme.colorScheme.surface,
          activeControlsWidgetColor: AppTheme.primaryAccent,
          lockAspectRatio: true,
          hideBottomControls: false,
          showCropGrid: true,
          initAspectRatio: CropAspectRatioPreset.square,
          dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
        ),
        IOSUiSettings(
          title: 'profile.crop_avatar'.tr(),
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: true,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _selectedImage = File(croppedFile.path);
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('wish.camera'.tr()),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    await _cropImage(image.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('wish.gallery'.tr()),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    await _cropImage(image.path);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();

      // Upload avatar if changed
      String? newAvatarUrl = _avatarUrl;
      if (_selectedImage != null) {
        newAvatarUrl = await apiService.uploadAvatarImage(
          imageFile: _selectedImage!,
        );

        if (newAvatarUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile.failed_to_upload_avatar'.tr()),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Update profile
      final result = await apiService.updateUserProfile(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: newAvatarUrl,
      );

      if (result != null && mounted) {
        // Refresh user data
        await context.read<AuthService>().syncUserWithBackend(retries: 1);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('profile.profile_updated'.tr()),
              backgroundColor: AppTheme.primaryAccent,
            ),
          );
          Navigator.pop(context);
        }
      } else if (mounted) {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.profile_update_failed'.tr()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_updateButtonState);
    _bioController.removeListener(_updateButtonState);
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool get _canSave {
    // Check if username is valid
    if (_usernameValidationError != null) return false;

    // If username changed, it must be available
    if (_usernameController.text.trim() != _originalUsername) {
      if (_usernameCheckResult != UsernameCheckStatus.available) return false;
    }

    // Full name is required
    if (_fullNameController.text.trim().isEmpty) return false;

    // Check if anything has changed
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user != null) {
      final hasChanges =
        _fullNameController.text.trim() != (user.name ?? '') ||
        _usernameController.text.trim() != (user.username ?? '') ||
        _bioController.text.trim() != (user.bio ?? '') ||
        _selectedImage != null;

      if (!hasChanges) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'profile.edit_profile_title'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
              // Avatar section
              Center(
                child: Stack(
                  children: [
                    _selectedImage != null
                        ? CircleAvatar(
                            radius: 60,
                            backgroundImage: FileImage(_selectedImage!),
                          )
                        : CachedAvatarImage(
                            imageUrl: _avatarUrl,
                            radius: 60,
                            backgroundColor: AppTheme.primaryAccent.withValues(alpha: 0.1),
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 3,
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Full Name field
              Text(
                'profile.full_name'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  hintText: 'profile.full_name_placeholder'.tr(),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'errors.validation_required'.tr();
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Username field
              Text(
                'profile.username'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                onChanged: _onUsernameChanged,
                maxLength: 30,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
                ],
                decoration: InputDecoration(
                  hintText: 'profile.username_placeholder'.tr(),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  counterText: '',
                  suffixIcon: _isCheckingUsername
                      ? Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryAccent.withValues(alpha: 0.6),
                          ),
                        )
                      : _usernameCheckResult == UsernameCheckStatus.available
                          ? Icon(Icons.check_circle, color: Colors.green.shade600, size: 20)
                          : null,
                  errorText: _usernameValidationError,
                  helperText: _usernameCheckResult != null &&
                             _usernameValidationError == null &&
                             _usernameController.text != _originalUsername
                      ? _getHelperText()
                      : null,
                  helperStyle: TextStyle(
                    color: _usernameCheckResult == UsernameCheckStatus.available
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bio field
              Text(
                'profile.bio'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'profile.bio_placeholder'.tr(),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
                ],
              ),
            ),
          ),

          // Fixed save button at bottom
          Padding(
            padding: EdgeInsets.fromLTRB(
              24.0,
              0.0,
              24.0,
              MediaQuery.of(context).padding.bottom + 16.0,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 62,
              child: ElevatedButton(
                onPressed: _isLoading || !_canSave ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E5EA),
                  disabledForegroundColor: const Color(0xFF8E8E93),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'profile.save_changes'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
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
}

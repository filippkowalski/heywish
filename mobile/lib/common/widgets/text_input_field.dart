import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TextInputField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final String? prefixText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  const TextInputField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
  });

  @override
  State<TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<TextInputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      validator: widget.validator,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixText: widget.prefixText,
        errorText: widget.errorText,
        
        // Icons
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: AppColors.textSecondary,
                size: 20,
              )
            : null,
            
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: _toggleObscureText,
              )
            : (widget.suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      widget.suffixIcon,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: widget.onSuffixIconPressed,
                  )
                : null),
        
        // Styling
        filled: true,
        fillColor: AppColors.surface,
        
        // Border styling
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.outline,
            width: 1,
          ),
        ),
        
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.outline,
            width: 1,
          ),
        ),
        
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.surfaceVariant,
            width: 1,
          ),
        ),
        
        // Text styling
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
        
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        
        floatingLabelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.primary,
        ),
        
        prefixStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
        
        errorStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.red,
        ),
        
        // Padding
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
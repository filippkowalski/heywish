import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../services/wishlist_service.dart';
import '../wishlist_new_screen.dart';

/// Currency code to symbol mapping
class CurrencyHelper {
  static String getSymbol(String currencyCode) {
    const symbolMap = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'CHF': 'CHF',
      'INR': '₹',
      'MXN': 'MX\$',
      'BRL': 'R\$',
      'KRW': '₩',
      'SEK': 'kr',
      'NOK': 'kr',
      'DKK': 'kr',
      'PLN': 'zł',
      'THB': '฿',
      'SGD': 'S\$',
      'HKD': 'HK\$',
      'NZD': 'NZ\$',
      'RUB': '₽',
      'ZAR': 'R',
      'TRY': '₺',
      'IDR': 'Rp',
      'HUF': 'Ft',
      'CZK': 'Kč',
      'ILS': '₪',
      'CLP': 'CLP\$',
      'PHP': '₱',
      'AED': 'د.إ',
      'COP': 'COL\$',
      'SAR': 'ر.س',
      'MYR': 'RM',
      'RON': 'lei',
    };
    return symbolMap[currencyCode] ?? currencyCode;
  }
}

/// Borderless text field used in wish forms
class WishFormTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final double fontSize;
  final FontWeight fontWeight;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final Color? textColor;
  final bool autofocus;

  const WishFormTextField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w400,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.textColor,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor ?? AppTheme.primary,
          height: 1.3,
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
        keyboardType: keyboardType,
      ),
    );
  }
}

/// Add field buttons (description, link, photo, price)
class WishFieldButtons extends StatelessWidget {
  final Set<String> visibleFields;
  final Function(String fieldKey) onFieldAdd;

  const WishFieldButtons({
    super.key,
    required this.visibleFields,
    required this.onFieldAdd,
  });

  @override
  Widget build(BuildContext context) {
    final availableFields = [
      if (!visibleFields.contains('description'))
        {'key': 'description', 'label': 'Description', 'icon': Icons.notes},
      if (!visibleFields.contains('url'))
        {'key': 'url', 'label': 'Link', 'icon': Icons.link},
      if (!visibleFields.contains('image'))
        {'key': 'image', 'label': 'Photo', 'icon': Icons.image},
      if (!visibleFields.contains('price'))
        {'key': 'price', 'label': 'Price', 'icon': Icons.attach_money},
    ];

    if (availableFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableFields.map((field) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onFieldAdd(field['key'] as String);
          },
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
        ),
      ],
    );
  }
}

/// Horizontal wishlist selector with "New List" button
class WishlistSelector extends StatelessWidget {
  final String? selectedWishlistId;
  final Function(String) onWishlistSelected;
  final VoidCallback onCreateNew;

  const WishlistSelector({
    super.key,
    required this.selectedWishlistId,
    required this.onWishlistSelected,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    final wishlistService = context.watch<WishlistService>();
    final wishlists = wishlistService.wishlists;

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wishlists.length + 1, // +1 for "New List" button
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          // First item is "New List" button
          if (index == 0) {
            return GestureDetector(
              onTap: onCreateNew,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: AppTheme.primaryAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'New List',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Remaining items are wishlists (offset by 1)
          final wishlist = wishlists[index - 1];
          final isSelected = selectedWishlistId == wishlist.id;

          return GestureDetector(
            onTap: () => onWishlistSelected(wishlist.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryAccent : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  wishlist.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Helper to create a new wishlist and return its ID
Future<String?> createNewWishlist(BuildContext context) async {
  // Show create new wishlist bottom sheet
  final newWishlistId = await WishlistNewScreen.show(context);

  if (newWishlistId != null && context.mounted) {
    // Refresh wishlists
    await context.read<WishlistService>().fetchWishlists();
    return newWishlistId.toString();
  }
  return null;
}

/// Close button for removable fields
class WishFieldCloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const WishFieldCloseButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.close,
          size: 20,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

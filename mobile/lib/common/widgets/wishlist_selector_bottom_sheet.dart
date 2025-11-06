import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/wishlist_service.dart';

class WishlistSelectorBottomSheet {
  static Future<String?> show({
    required BuildContext context,
  }) async {
    if (Platform.isIOS) {
      return _showCupertinoBottomSheet(context: context);
    } else {
      return _showMaterialBottomSheet(context: context);
    }
  }

  static Future<String?> _showCupertinoBottomSheet({
    required BuildContext context,
  }) async {
    final wishlistService = context.read<WishlistService>();
    await wishlistService.fetchWishlists();
    final allWishlists = wishlistService.wishlists;
    // Filter out synthetic "All Wishes" wishlist
    final wishlists = allWishlists.where((w) => !w.isSynthetic).toList();

    if (wishlists.isEmpty) {
      return null;
    }

    if (!context.mounted) return null;

    return showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text('wishlist.add_to_wishlist'.tr()),
          message: Text(
            'Select a wishlist to add this item to',
            style: const TextStyle(fontSize: 13),
          ),
          actions: wishlists.map((wishlist) {
            return CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop(wishlist.id);
              },
              child: Text(wishlist.name),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('app.cancel'.tr()),
          ),
        );
      },
    );
  }

  static Future<String?> _showMaterialBottomSheet({
    required BuildContext context,
  }) async {
    final wishlistService = context.read<WishlistService>();
    await wishlistService.fetchWishlists();
    final allWishlists = wishlistService.wishlists;
    // Filter out synthetic "All Wishes" wishlist
    final wishlists = allWishlists.where((w) => !w.isSynthetic).toList();

    if (wishlists.isEmpty) {
      return null;
    }

    if (!context.mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'wishlist.add_to_wishlist'.tr(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a wishlist to add this item to',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Wishlist list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: wishlists.length,
                    itemBuilder: (context, index) {
                      final wishlist = wishlists[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.card_giftcard,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        title: Text(
                          wishlist.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: wishlist.description != null &&
                                wishlist.description!.isNotEmpty
                            ? Text(
                                wishlist.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () {
                          Navigator.of(context).pop(wishlist.id);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

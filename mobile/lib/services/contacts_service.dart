import 'package:flutter/foundation.dart';
// import 'package:contacts_service/contacts_service.dart' as contact_service;
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import '../utils/phone_utils.dart';

/// Isolate function for processing phone numbers off the main thread
List<String> _processPhoneNumbersInIsolate(List<String> rawPhoneNumbers) {
  debugPrint('🔄 Processing ${rawPhoneNumbers.length} phone numbers in isolate');
  
  // Use robust phone normalization that matches backend logic
  final normalizedNumbers = preparePhoneNumbersForMatching(rawPhoneNumbers);
  
  debugPrint('✅ Processed ${rawPhoneNumbers.length} raw numbers to ${normalizedNumbers.length} searchable variants');
  return normalizedNumbers;
}

class ContactsService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _friendSuggestions = [];
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get friendSuggestions => _friendSuggestions;
  
  /// Request contact book permission
  Future<bool> requestContactPermission() async {
    try {
      debugPrint('📱 ContactsService: Requesting contact permission');
      
      final status = await Permission.contacts.request();
      final granted = status == PermissionStatus.granted;
      
      debugPrint('📱 ContactsService: Contact permission granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('❌ ContactsService: Error requesting permission: $e');
      _error = 'Failed to request contact permission';
      notifyListeners();
      return false;
    }
  }
  
  /// Check if contact permission is granted
  Future<bool> hasContactPermission() async {
    final status = await Permission.contacts.status;
    return status == PermissionStatus.granted;
  }
  
  /// Load contacts locally and extract only phone numbers (PRIVACY-FIRST)
  Future<List<String>> getContactPhoneNumbers() async {
    try {
      debugPrint('📱 ContactsService: Loading contacts locally for phone numbers only');
      
      // Check permission first
      if (!(await hasContactPermission())) {
        _error = 'Contact permission not granted';
        notifyListeners();
        return [];
      }
      
      // Load contacts locally - TEMPORARILY DISABLED
      // final rawContacts = await contact_service.ContactsService.getContacts(withThumbnails: false);
      
      // Extract raw phone numbers (NO NAMES OR OTHER DATA) - TEMPORARILY DISABLED
      final rawPhoneNumbers = <String>[]; // TODO: Re-enable when contacts_service is fixed
      // final rawPhoneNumbers = rawContacts
      //     .where((contact) => contact.phones != null && contact.phones!.isNotEmpty)
      //     .expand((contact) => contact.phones!)
      //     .map((phone) => phone.value ?? '')
      //     .where((phone) => phone.isNotEmpty)
      //     .toList();
      
      debugPrint('📱 ContactsService: Extracted ${rawPhoneNumbers.length} raw numbers');
      
      // Process phone numbers off main thread for better performance
      final normalizedNumbers = await compute(_processPhoneNumbersInIsolate, rawPhoneNumbers);
      
      debugPrint('📱 ContactsService: Normalized to ${normalizedNumbers.length} searchable variants (names NOT included)');
      return normalizedNumbers;
      
    } catch (e) {
      debugPrint('❌ ContactsService: Error loading contacts: $e');
      _error = 'Failed to load contacts';
      notifyListeners();
      return [];
    }
  }
  
  /// Privacy-first friend discovery: Only send phone numbers, never contact names
  Future<bool> findFriendsFromContacts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      debugPrint('🔍 ContactsService: Starting privacy-first friend discovery');
      
      // Get phone numbers only (no names or other data)
      final phoneNumbers = await getContactPhoneNumbers();
      
      if (phoneNumbers.isEmpty) {
        _friendSuggestions = [];
        _error = 'No contacts available';
        return false;
      }
      
      // Send only phone numbers to backend (PRIVACY-FIRST)
      final response = await _apiService.findFriendsByPhoneNumbers(phoneNumbers);
      
      if (response != null && response['suggestions'] != null) {
        _friendSuggestions = List<Map<String, dynamic>>.from(response['suggestions']);
        debugPrint('✅ ContactsService: Found ${_friendSuggestions.length} friend suggestions (privacy-first)');
        return true;
      } else {
        _friendSuggestions = [];
        _error = 'No friends found in contacts';
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ ContactsService: Error finding friends: $e');
      _error = 'Failed to find friends';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
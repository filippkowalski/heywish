/// Robust phone number normalization for global matching
/// Mirrors the backend phone_utils.js implementation to ensure consistency

// US/Canada area codes (to distinguish from country codes)
const Set<String> usAreaCodes = {
  '201', '202', '203', '205', '206', '207', '208', '209', '210', '212', '213', '214', '215', '216', '217', '218', '219',
  '224', '225', '227', '228', '229', '231', '234', '239', '240', '248', '251', '252', '253', '254', '256', '260',
  '262', '267', '269', '270', '272', '276', '281', '283', '301', '302', '303', '304', '305', '307', '308', '309',
  '310', '312', '313', '314', '315', '316', '317', '318', '319', '320', '321', '323', '325', '330', '331', '334',
  '336', '337', '339', '341', '346', '347', '351', '352', '360', '361', '364', '365', '380', '385', '386', '401',
  '402', '404', '405', '406', '407', '408', '409', '410', '412', '413', '414', '415', '417', '419', '423', '424',
  '425', '430', '432', '434', '435', '440', '442', '443', '445', '447', '458', '463', '464', '469', '470', '475',
  '478', '479', '480', '484', '501', '502', '503', '504', '505', '507', '508', '509', '510', '512', '513', '515',
  '516', '517', '518', '520', '530', '531', '534', '539', '540', '541', '551', '559', '561', '562', '563', '564',
  '567', '570', '571', '573', '574', '575', '580', '585', '586', '601', '602', '603', '605', '606', '607', '608',
  '609', '610', '612', '614', '615', '616', '617', '618', '619', '620', '623', '626', '628', '629', '630', '631',
  '636', '641', '646', '650', '651', '657', '660', '661', '662', '667', '669', '678', '681', '682', '701', '702',
  '703', '704', '706', '707', '708', '712', '713', '714', '715', '716', '717', '718', '719', '720', '724', '725',
  '727', '731', '732', '734', '737', '740', '747', '754', '757', '760', '762', '763', '765', '769', '770', '772',
  '773', '774', '775', '779', '781', '785', '786', '787', '801', '802', '803', '804', '805', '806', '808', '810',
  '812', '813', '814', '815', '816', '817', '818', '828', '830', '831', '832', '843', '845', '847', '848', '850',
  '856', '857', '858', '859', '860', '862', '863', '864', '865', '870', '872', '878', '901', '903', '904', '906',
  '907', '908', '909', '910', '912', '913', '914', '915', '916', '917', '918', '919', '920', '925', '928', '929',
  '930', '931', '934', '936', '937', '938', '940', '941', '947', '949', '951', '952', '954', '956', '959', '970',
  '971', '972', '973', '975', '978', '979', '980', '984', '985', '989'
};

/// Normalize a phone number for consistent matching
/// [phone] - Raw phone number from contact book or user input
/// [defaultCountryCode] - Default country code if none detected (e.g., '+1')
/// Returns normalized phone number in E.164 format or null if invalid
String? normalizePhoneNumber(String? phone, [String defaultCountryCode = '+1']) {
  if (phone == null || phone.isEmpty) return null;
  
  // Remove all non-digit characters except +
  String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
  
  // Remove leading zeros (except for +)
  cleaned = cleaned.replaceAll(RegExp(r'^0+'), '');
  
  // Handle different input formats
  if (cleaned.startsWith('+')) {
    // Already has country code
    return cleaned;
  } else if (cleaned.length == 10) {
    // Likely US/Canada number without country code
    // Check if first 3 digits are valid US area code
    final areaCode = cleaned.substring(0, 3);
    if (usAreaCodes.contains(areaCode)) {
      return '+1$cleaned';
    } else {
      // Could be international number without +, use default
      return '$defaultCountryCode$cleaned';
    }
  } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
    // US/Canada number with leading 1
    final areaCode = cleaned.substring(1, 4);
    if (usAreaCodes.contains(areaCode)) {
      return '+$cleaned';
    } else {
      // Not a valid US number, treat as international
      return '$defaultCountryCode${cleaned.substring(1)}';
    }
  } else if (cleaned.length >= 7 && cleaned.length <= 15) {
    // International number without country code
    return '$defaultCountryCode$cleaned';
  }
  
  // Invalid phone number
  return null;
}

/// Generate multiple normalized variations of a phone number for matching
/// This handles cases where the same number might be stored differently
/// [phone] - Raw phone number
/// [userCountryCode] - User's country code for context
/// Returns list of possible normalized formats
List<String> generatePhoneVariations(String phone, [String userCountryCode = '+1']) {
  final variations = <String>{};
  
  // Primary normalization
  final primary = normalizePhoneNumber(phone, userCountryCode);
  if (primary != null) variations.add(primary);
  
  // Try without country code (for local storage)
  final withoutCountry = normalizePhoneNumber(phone, '');
  if (withoutCountry != null && withoutCountry != primary) {
    variations.add(withoutCountry);
  }
  
  // Try with different country codes for common cases
  const commonCodes = ['+1', '+44', '+49', '+33', '+61'];
  for (final code in commonCodes) {
    final variant = normalizePhoneNumber(phone, code);
    if (variant != null && variant != primary) {
      variations.add(variant);
    }
  }
  
  // Remove duplicates and invalid entries
  return variations.where((v) => v.length >= 8).toList();
}

/// Smart phone number matching that tries multiple formats
/// [contactPhones] - Phone numbers from contact book
/// [userCountryCode] - User's detected country code
/// Returns optimized list of phone numbers for database matching
List<String> preparePhoneNumbersForMatching(List<String> contactPhones, [String userCountryCode = '+1']) {
  final allVariations = <String>{};
  
  for (final phone in contactPhones) {
    final variations = generatePhoneVariations(phone, userCountryCode);
    allVariations.addAll(variations);
  }
  
  return allVariations.toList();
}

/// Detect user's country code from their phone number format
/// [userPhone] - User's own phone number
/// Returns detected country code or default '+1'
String detectCountryCode(String? userPhone) {
  if (userPhone == null || userPhone.isEmpty) return '+1';
  
  final normalized = normalizePhoneNumber(userPhone);
  if (normalized == null) return '+1';
  
  // Extract country code from normalized number
  if (normalized.startsWith('+1')) return '+1';
  if (normalized.startsWith('+44')) return '+44';
  if (normalized.startsWith('+49')) return '+49';
  if (normalized.startsWith('+33')) return '+33';
  if (normalized.startsWith('+61')) return '+61';
  
  // Default to US/Canada
  return '+1';
}
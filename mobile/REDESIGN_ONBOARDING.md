# Onboarding Redesign Implementation Guide

This document contains all the changes needed to implement the minimal-text, shadcn/Tailwind-inspired onboarding redesign.

## Key Design Principles Applied:
- **Minimal Text**: Max 1 title + 1 subtitle per screen
- **Visual First**: Large images, generous white space
- **Shadcn/Tailwind Style**: Clean cards, subtle shadows, soft colors
- **Fogg Model**: Micro-rewards, motivation through progress

## New Flow:
1. Welcome - Hero image, 2 lines of text
2. Feature Organize - Animated, minimal text
3. Account Creation - Clean buttons
4. Username - Simple input
5. Username Confirmation - Shareable link (DONE ✅)
6. Profile Details - Minimal fields only
7. **Shopping Interests (NEW)** - Visual chips
8. Feature Share - Animated, minimal text
9. Notifications - Visual toggles
10. Complete - Celebration (DONE ✅)

## Files to Modify:

### 1. Add Shopping Interests to Enum
File: `/Users/filip.zapper/Workspace/heywish/mobile/lib/services/onboarding_service.dart`

Find the enum and add `shoppingInterests` after `profileDetails`:
```dart
enum OnboardingStep {
  welcome,
  featureOrganize,
  accountCreation,
  checkUserStatus,
  username,
  usernameConfirmation,
  profileDetails,
  shoppingInterests,     // ADD THIS LINE
  featureShare,
  notifications,
  complete
}
```

### 2. Update OnboardingData class
In same file, add shopping interests field:
```dart
class OnboardingData {
  String? username;
  String? fullName;
  DateTime? birthday;
  String? gender;
  List<String> shoppingInterests; // ADD THIS
  Map<String, bool> notificationPreferences;
  bool contactPermissionGranted;
  List<Map<String, dynamic>> friendSuggestions;

  OnboardingData({
    this.username,
    this.fullName,
    this.birthday,
    this.gender,
    List<String>? shoppingInterests, // ADD THIS
    Map<String, bool>? notificationPreferences,
    this.contactPermissionGranted = false,
    List<Map<String, dynamic>>? friendSuggestions,
  }) : shoppingInterests = shoppingInterests ?? [], // ADD THIS
       notificationPreferences = notificationPreferences ?? {...},
       friendSuggestions = friendSuggestions ?? [];
```

### 3. Update nextStep() method
Add case for profileDetails to go to shoppingInterests:
```dart
case OnboardingStep.profileDetails:
  _currentStep = OnboardingStep.shoppingInterests; // CHANGE THIS
  break;
case OnboardingStep.shoppingInterests: // ADD THIS
  _currentStep = OnboardingStep.featureShare;
  break;
```

### 4. Update previousStep() method
```dart
case OnboardingStep.shoppingInterests: // ADD THIS
  _currentStep = OnboardingStep.profileDetails;
  break;
case OnboardingStep.featureShare:
  _currentStep = OnboardingStep.shoppingInterests; // CHANGE THIS
  break;
```

### 5. Update canProceedFromCurrentStep()
```dart
case OnboardingStep.shoppingInterests: // ADD THIS
  return true; // Optional, can proceed even without selections
```

### 6. Update toProfileUpdateData()
```dart
Map<String, dynamic> toProfileUpdateData() {
  return {
    'username': username,
    'full_name': fullName,
    'birthdate': birthday?.toIso8601String(),
    'gender': gender,
    'shopping_interests': shoppingInterests, // ADD THIS
    'notification_preferences': notificationPreferences,
    'privacy_settings': {
      'phone_discoverable': contactPermissionGranted,
      'show_birthday': true,
      'show_gender': false,
    },
  };
}
```

## Next Steps:
1. Run the sed commands below to update the enum
2. Manually update OnboardingData class
3. Create shopping_interests_step.dart (see SHOPPING_INTERESTS_STEP.dart)
4. Update onboarding_flow_screen.dart to add the new case
5. Update backend to handle shopping_interests
6. Run database migration

## Sed Commands to Run:
```bash
cd /Users/filip.zapper/Workspace/heywish/mobile/lib/services

# Add shoppingInterests to enum (after profileDetails)
sed -i '' '/profileDetails,/a\
  shoppingInterests,     // Visual category selector
' onboarding_service.dart

# Update profileDetails case in nextStep
sed -i '' 's/profileDetails:$/profileDetails:\n        _currentStep = OnboardingStep.shoppingInterests;\n        break;\n      case OnboardingStep.shoppingInterests:/' onboarding_service.dart

# Add case in canProceedFromCurrentStep
sed -i '' '/case OnboardingStep.profileDetails:/a\
      case OnboardingStep.shoppingInterests:\n        return true; // Optional, can proceed without selections
' onboarding_service.dart
```

## Backend Changes Needed:
1. Run migration: `/Users/filip.zapper/Workspace/heywish/migrations/20250330_add_shopping_interests.sql`
2. Update `syncUser()` to accept shopping_interests array
3. Update profile update endpoint to save shopping_interests

This is a large refactor - implement step by step and test thoroughly!
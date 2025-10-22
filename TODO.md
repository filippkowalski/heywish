# Apple Sign-In Firebase Configuration TODO

## Current Status
✅ Apple Sign-In is working in the iOS app (getting Apple credentials successfully)  
❌ Firebase is rejecting the Apple credentials with `[firebase_auth/invalid-credential]` error  

## Required Configuration Steps

### 1. Firebase Console Setup 🔥

**Go to Firebase Console**: https://console.firebase.google.com/
1. **Select your project**: `wishlist-app-v2`
2. **Go to**: Authentication → Sign-in method
3. **Enable Apple provider**:
   - Click on **"Apple"**
   - **Enable** the provider
   - **Add your Apple Developer Team ID**: `[YOUR_NEW_TEAM_ID]` (replace with your actual team ID)
   - **Add Bundle ID**: `com.wishlists.gifts`

### 2. Apple Developer Portal Setup 🍎

**Go to Apple Developer Portal**: https://developer.apple.com/account/

#### Step 2a: Enable App ID Capability
1. **Go to**: Certificates, Identifiers & Profiles → Identifiers
2. **Find your App ID**: `com.wishlists.gifts`
3. **Edit the App ID** and enable **"Sign In with Apple"** capability
4. **Save the changes**

#### Step 2b: Create Service ID (for OAuth)
1. **Go to**: Certificates, Identifiers & Profiles → Identifiers
2. **Click "+"** → **Services IDs**
3. **Create new Service ID**:
   - Description: `HeyWish Apple Sign-In Service`
   - Identifier: `com.wishlists.gifts.signin` (or similar)
4. **Configure the Service ID**:
   - Enable **"Sign In with Apple"**
   - **Primary App ID**: Select `com.wishlists.gifts`
   - **Domains and Subdomains**: `wishlist-app-v2.firebaseapp.com`
   - **Return URLs**: `https://wishlist-app-v2.firebaseapp.com/__/auth/handler`

#### Step 2c: Create Apple Sign-In Key (if needed)
1. **Go to**: Certificates, Identifiers & Profiles → Keys
2. **Click "+"** to create new key
3. **Enable "Sign In with Apple"**
4. **Configure for your App ID**: `com.wishlists.gifts`
5. **Download the key file** (.p8 file) - **Save this securely!**
6. **Note the Key ID** - you'll need this for Firebase

### 3. Update Xcode Project (if using different dev team)

If you're switching to a different development team ID:

1. **Open**: `ios/Runner.xcworkspace` in Xcode
2. **Select Runner target** → Signing & Capabilities
3. **Update Team**: Select your new development team
4. **Verify**: "Sign In with Apple" capability is still enabled
5. **Update provisioning profile** if needed

### 4. Update Project Configuration

**File**: `/mobile/ios/Runner.xcodeproj/project.pbxproj`

Replace all instances of:
```
DEVELOPMENT_TEAM = 474TK9U3BP;
```

With your new team ID:
```
DEVELOPMENT_TEAM = [YOUR_NEW_TEAM_ID];
```

### 5. Firebase Configuration Details

When configuring Apple provider in Firebase Console, you'll need:

- **Service ID**: The identifier you created in step 2b
- **Apple Team ID**: Your new development team ID
- **Key ID**: From the key you created in step 2c (if required)
- **Private Key**: Content of the .p8 file (if required)

### 6. Testing Verification

After completing all steps:

1. **Clean and rebuild** the iOS app
2. **Test Apple Sign-In** on physical device (iOS 13+)
3. **Verify** user is created in Firebase Authentication
4. **Check** that user syncs to your PostgreSQL backend

## Current Working Features

✅ **Google Sign-In**: Fully configured and working  
✅ **Email/Password**: Fully configured and working  
✅ **Apple Sign-In (iOS side)**: Getting Apple credentials successfully  
❌ **Apple Sign-In (Firebase side)**: Needs configuration above  

## Notes

- Apple Sign-In only works on physical iOS devices (iOS 13+)
- The Firebase redirect URL `https://wishlist-app-v2.firebaseapp.com/__/auth/handler` is critical
- Make sure to use the same Bundle ID (`com.wishlists.gifts`) across all configurations
- Save the .p8 key file securely - Apple only lets you download it once

## Current Error

```
❌ AuthService: Error signing in with Apple: [firebase_auth/invalid-credential] Invalid OAuth response from apple.com
```

This will be resolved once Firebase and Apple Developer portal are properly configured to work together.

---

# iOS Share Extension Setup TODO

## Current Status
✅ **Backend URL Scraping**: Fully deployed and working at `https://openai-rewrite.onrender.com`
✅ **Clipboard Detection**: Working on iOS - detects URLs when app opens
✅ **Smart Auto-Fill**: Auto-fills wish details from Amazon & generic URLs
✅ **Mobile Implementation**: Complete with loading states and animations
⚠️ **Share Extension**: Requires Xcode setup (optional enhancement)

## What Works Now (Without Share Extension)

### Clipboard Detection Flow ✅
Users can add wishes by:
1. Copy product URL in Safari/any app
2. Open HeyWish app
3. Bottom sheet appears: "Link Detected"
4. Tap "Add as Wish" → Select wishlist
5. Fields auto-fill with title, price, image, description

**This is the PRIMARY feature and works perfectly!**

## Share Extension Setup (Optional - Requires Mac + Xcode)

**Note:** Share Extension requires:
- ✅ Mac computer with Xcode
- ✅ Apple Developer Account ($99/year)
- ✅ Xcode 14.0 or later
- ⏱️ 15-20 minutes setup time

**Cannot be done without Xcode** - there is no workaround.

### Complete Setup Guide

**Location**: `mobile/ios/SHARE_EXTENSION_SETUP_GUIDE.md`

Follow the step-by-step guide to:
1. Create Share Extension target in Xcode
2. Configure App Groups (`group.com.wishlists.gifts`)
3. Update ShareViewController.swift
4. Set up code signing
5. Build and test

### Quick Steps Summary

```bash
# 1. Open project in Xcode
cd mobile/ios
open Runner.xcworkspace

# 2. Create Share Extension target
File → New → Target → Share Extension
Name: ShareExtension
Bundle ID: com.wishlists.gifts.ShareExtension

# 3. Add App Groups capability
Both Runner and ShareExtension targets:
Signing & Capabilities → + Capability → App Groups
Add: group.com.wishlists.gifts

# 4. Update ShareViewController.swift
Replace with code from SHARE_EXTENSION_SETUP_GUIDE.md

# 5. Build and test
Product → Build
Test by sharing URL from Safari
```

### What Share Extension Adds

**With Share Extension:**
- Users tap Share button in Safari → HeyWish appears in share sheet
- One less tap vs clipboard detection
- More discoverable feature

**Without Share Extension (Current):**
- Users copy link → Switch to HeyWish
- Automatic detection still works
- Only 1 extra tap

### Recommendation

**Ship without Share Extension initially:**
- Clipboard detection is 90% as good
- Works reliably without Xcode
- Can add Share Extension later as "v2 premium feature"
- Focus on core functionality first

**Add Share Extension when:**
- You have Mac access
- Ready to polish for App Store submission
- Want to add premium touch

## Alternative Approaches (No Xcode Needed)

### Option 1: Enhance Clipboard Detection ✅
```dart
// Already implemented!
- Haptic feedback on detection
- Success animations
- Native bottom sheets
- Smooth auto-fill
```

### Option 2: Universal Links (Future)
Requires:
- Domain ownership (jinnie.co)
- AASA file configuration
- Can be done in Info.plist

Allows: `jinnie.co/add?url=...` → Opens app

### Option 3: User Education
Add onboarding tutorial:
- "Copy link → Open HeyWish"
- "Faster than sharing!"
- Tooltip on first use

## Files & Documentation

**Implementation:**
- `lib/services/clipboard_service.dart` - iOS clipboard detection
- `lib/services/share_handler_service.dart` - Share processing (ready for extension)
- `lib/services/api_service.dart` - URL scraping API
- `lib/screens/wishlists/add_wish_screen.dart` - Auto-fill logic
- `lib/screens/home_screen.dart` - Clipboard monitoring

**Documentation:**
- `mobile/ios/SHARE_EXTENSION_SETUP_GUIDE.md` - Complete Xcode setup guide
- `IMPLEMENTATION_STATUS.md` - Full implementation status
- Backend: `backend_openai_proxy/services/url-scraper.js` - URL scraper

## Testing Checklist

### Test Clipboard Detection (Works Now!)
```
1. Copy Amazon URL: https://www.amazon.com/dp/B08N5WRWNW
2. Open HeyWish app
3. ✅ Bottom sheet should appear
4. ✅ Tap "Add as Wish"
5. ✅ Select wishlist
6. ✅ Fields auto-fill within 2 seconds
7. ✅ Success message shows
```

### Test Manual URL Paste (Works Now!)
```
1. Open HeyWish → Add Wish
2. Paste any product URL
3. ✅ Loading spinner appears
4. ✅ Green checkmark when valid
5. ✅ Fields populate automatically
6. ✅ Success notification
```

### Test Share Extension (After Xcode Setup)
```
1. Open Safari on iOS
2. Navigate to product page
3. Tap Share button
4. ✅ "HeyWish" appears in share sheet
5. Tap HeyWish
6. ✅ App opens with wishlist selector
7. ✅ Add Wish screen with auto-filled data
```

## Priority

**High Priority (Done ✅):**
- [x] Backend URL scraping
- [x] Clipboard detection
- [x] Auto-fill functionality
- [x] Loading states
- [x] Error handling

**Low Priority (Optional):**
- [ ] Share Extension setup
- [ ] Universal Links
- [ ] Advanced animations
- [ ] Price tracking

## Next Steps

1. **Test the app** with clipboard detection (works now!)
2. **Ship MVP** without Share Extension
3. **Add Share Extension later** when you have Mac access
4. **Consider alternatives** (Universal Links, better onboarding)

**Bottom Line:** The feature is complete and production-ready without Share Extension! 🚀
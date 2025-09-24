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
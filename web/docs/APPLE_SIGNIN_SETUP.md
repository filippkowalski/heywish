# Apple Sign-in Web Setup Guide

This guide walks you through setting up Apple Sign-in for the Jinnie web application.

## Overview

Apple Sign-in is already configured for the mobile app. This guide covers the additional steps needed to enable it on the web platform.

## Prerequisites

- Access to Apple Developer Portal (developer.apple.com)
- Access to Firebase Console
- The app is already configured for Apple Sign-in on iOS/Android

## Step 1: Apple Developer Portal Configuration

### 1.1 Create a Services ID

A Services ID is required for web-based Apple Sign-in (different from your App ID).

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles** → **Identifiers**
3. Click the **+** button to create a new identifier
4. Select **Services IDs** and click Continue
5. Configure the Services ID:
   - **Description**: `Jinnie Web Sign In` (or similar)
   - **Identifier**: `com.wishlists.gifts.web` (must be unique)
   - Click Continue, then Register

### 1.2 Configure Sign In with Apple for Services ID

1. In the Identifiers list, find and click your newly created Services ID
2. Check **Sign In with Apple**
3. Click **Configure** next to "Sign In with Apple"
4. Configure the following:
   - **Primary App ID**: Select your existing app ID (`com.wishlists.gifts`)
   - **Domains and Subdomains**: Add your domains:
     - `wishlist-app-v2.firebaseapp.com`
     - Your production domain (e.g., `jinnie.app`)
   - **Return URLs**: Add Firebase auth handler:
     - `https://wishlist-app-v2.firebaseapp.com/__/auth/handler`
     - If you have a custom domain, also add: `https://yourdomain.com/__/auth/handler`
5. Click **Save**, then **Continue**, then **Save** again

### 1.3 Create Sign In with Apple Key

You need a private key for server-side verification:

1. Go to **Certificates, Identifiers & Profiles** → **Keys**
2. Click the **+** button to create a new key
3. Configure the key:
   - **Key Name**: `Apple Sign In Key (Web)`
   - Check **Sign In with Apple**
   - Click **Configure** next to "Sign In with Apple"
   - Select your Primary App ID: `com.wishlists.gifts`
   - Click **Save**
4. Click **Continue**, then **Register**
5. **IMPORTANT**: Download the .p8 file immediately (you can only download it once!)
6. Note your **Key ID** (displayed on the download page)
7. Note your **Team ID** (in the top right of the developer portal)

## Step 2: Firebase Console Configuration

### 2.1 Enable Apple Sign-in Provider

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `wishlist-app-v2`
3. Navigate to **Authentication** → **Sign-in method**
4. Find **Apple** in the list and click on it
5. Toggle **Enable**

### 2.2 Configure OAuth Code Flow

1. In the Apple provider settings:
   - **Service ID**: Enter your Services ID: `com.wishlists.gifts.web`
   - **Team ID**: Enter your Apple Team ID
   - **Key ID**: Enter the Key ID from Step 1.3
   - **Private Key**: Open your downloaded .p8 file and paste its contents (including BEGIN and END lines)

2. Click **Save**

### 2.3 Note the OAuth Redirect URI

Firebase will display an OAuth redirect URI that looks like:
```
https://wishlist-app-v2.firebaseapp.com/__/auth/handler
```

**This must match** the Return URL you configured in Apple Developer Portal (Step 1.2).

## Step 3: Verify the Setup

### 3.1 Check Apple Developer Portal

Verify in Apple Developer Portal:
- ✅ Services ID is created and configured
- ✅ Sign In with Apple is enabled for the Services ID
- ✅ Domains are correctly configured
- ✅ Return URLs match Firebase's OAuth redirect URI
- ✅ Key is created and downloaded

### 3.2 Check Firebase Console

Verify in Firebase Console:
- ✅ Apple provider is enabled
- ✅ Service ID, Team ID, and Key ID are entered correctly
- ✅ Private key is pasted correctly

### 3.3 Test the Implementation

1. Start your development server: `npm run dev`
2. Navigate to your web app
3. Click "Sign In" and choose "Continue with Apple"
4. You should see the Apple Sign-in popup
5. Complete the sign-in flow
6. Verify you're signed in and synced with the backend

## Troubleshooting

### Common Issues

#### 1. "Invalid client" or "invalid_client" error
- **Cause**: Services ID or configuration mismatch
- **Fix**: Double-check your Services ID in both Apple Developer Portal and Firebase Console

#### 2. "redirect_uri_mismatch" error
- **Cause**: Return URL doesn't match Firebase's OAuth redirect URI
- **Fix**: Ensure the Return URL in Apple Developer Portal exactly matches Firebase's OAuth redirect URI

#### 3. "Invalid key" or authentication fails silently
- **Cause**: Private key not configured correctly
- **Fix**: Re-paste the entire .p8 file contents (including BEGIN/END lines) in Firebase Console

#### 4. Popup blocked
- **Cause**: Browser is blocking popups
- **Fix**: Allow popups for your domain or try a different browser

#### 5. "Apple Sign-in is not configured" on mobile
- **Cause**: This setup is only for web
- **Fix**: Mobile uses different configuration (already set up via Xcode capabilities)

## Implementation Details

### Code Changes Made

The following files were updated to support Apple Sign-in:

1. **`web/lib/firebase.client.ts`**
   - Added `OAuthProvider` for Apple
   - Configured Apple provider with email and name scopes

2. **`web/lib/auth/AuthContext.client.tsx`**
   - Added `signInWithApple` method
   - Updated auth sync to detect Apple provider
   - Added error handling for Apple-specific errors

3. **`web/components/auth/SignInModal.client.tsx`**
   - Added Apple Sign-in button with Apple branding
   - Added separate loading states for Google and Apple
   - Disabled buttons while either sign-in is in progress

### How It Works

1. User clicks "Continue with Apple" button
2. `signInWithApple()` is called, which opens a popup
3. User authenticates with Apple ID
4. Apple returns credentials to Firebase
5. Firebase creates/signs in the user
6. `onIdTokenChanged` listener fires
7. User is synced with backend via `/api/auth/sync`
8. Backend receives `signUpMethod: 'apple'`

## Security Notes

- **Private Key (.p8 file)**: Store securely and never commit to version control
- **Service ID**: This is public and can be seen in your web app's code
- **Team ID**: Also public
- **Key ID**: Also public

The security comes from the private key, which only Firebase has access to.

## Next Steps

After completing this setup:

1. ✅ Test Apple Sign-in on localhost
2. ✅ Test Apple Sign-in on staging environment
3. ✅ Add your production domain to Apple Developer Portal
4. ✅ Update Return URLs for production
5. ✅ Test Apple Sign-in on production
6. ✅ Monitor for any authentication errors in Firebase Console

## References

- [Firebase Authentication - Apple Sign-in](https://firebase.google.com/docs/auth/web/apple)
- [Apple Developer - Sign In with Apple](https://developer.apple.com/sign-in-with-apple/)
- [Apple Developer - Configuring Your Webpage](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_js/configuring_your_webpage_for_sign_in_with_apple)

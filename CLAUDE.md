# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## App Features Overview

HeyWish combines wishlist management, social features, and gift coordination across mobile (Flutter) and web (Next.js) platforms.

### Mobile App Pages/Screens (Flutter)
- **Authentication & Onboarding**: Splash screen, login/signup, 7-step guided onboarding (username, profile, notifications, friend discovery, account creation)
- **Main Navigation**: Home/Wishlists tab (view/create wishlists), Discover tab (categories/people search), Profile tab
- **Wishlist & Item Management**: Wishlist detail/edit/create screens, add/edit wish screens
- **Social Features**: Friends screen (friends/requests tabs), Activity feed with filters

### Web App Pages (Next.js)
- **Marketing & Public**: Homepage, About, Blog, Public shareable wishlist pages
- **Web Application**: Dashboard with anonymous onboarding, Create wishlist page

### General Features (Cross-Platform)
- **Authentication**: Firebase integration (anonymous, Google, Apple, email/password), account linking
- **Core Services**: API integration, wishlist management, social/friends, contact integration
- **Offline & Sync**: Local SQLite database, offline-first architecture, background sync
- **Media & Content**: Cloudflare R2 image management, URL scraping, cached images
- **UI/UX**: Skeleton loading, Material Design 3, multi-language support, optimistic UI
- **Backend**: Global search, reservation system, activity feeds, file uploads, sharing system

## Project Overview

HeyWish is a next-generation wishlist platform that aims to compete with GoWish by offering a modern, fast, and social-first experience targeting younger demographics.

## Technology Stack

- **Backend/Web**: Next.js 14 with App Router (modular monolith approach)
- **Authentication**: Firebase Auth (free tier, no Identity Platform)
- **Database**: PostgreSQL hosted on Render.com
- **Mobile**: Flutter
- **Styling**: Tailwind CSS (for web)
- **Infrastructure**: Cloudflare Pages for deployment
- **CDN/Storage**: Cloudflare R2 (images storage)

## Architecture Principles

- **Modular Monolith**: The backend is implemented as a modular monolith within the Next.js application, using API routes organized by domain (auth, wishlists, wishes, users, social).
- **Authentication Flow**: Firebase handles auth, and user data is synced to the PostgreSQL database on first login.
- **Database**: A single PostgreSQL instance is used, hosted on Render.com.

## Key Documentation Files

Review these files for context:
- `docs/DESIGN_SYSTEM.md` - UI components and styling guidelines
- `docs/API_SPECIFICATION.md` - Detailed description of the REST API.
- `docs/TECHNICAL_SPEC.md` - Database schema and technical details.

## Database Schema

The PostgreSQL schema is defined in `docs/TECHNICAL_SPEC.md`. Key tables include:
- `users` - User accounts synced from Firebase (includes firebase_uid)
- `wishlists` - User wishlists with visibility settings
- `wishes` - Individual wish items with reservation status
- Social features tables (friends, activity feed)

## Authentication Integration

1. Users must create an account to use the app - no anonymous access.
2. Firebase handles all authentication methods (email/password, Google, Apple).
3. On any Firebase authentication event, the `/api/auth/sync` endpoint is called to create or update the user in the PostgreSQL database.
4. All API calls require a valid Firebase ID token in the `Authorization` header.
5. The backend verifies the token with the Firebase Admin SDK before processing requests.

## API Structure

The REST API is implemented using Next.js API routes. Key characteristics include:
- Base path: `/api/v1`
- Authentication: Firebase ID tokens are verified on the backend.
- Standard HTTP methods and status codes are used.
- The request and response format is JSON.
- Key authentication endpoints include `/api/auth/sync` and `/api/auth/verify`.

## WEB Guidelines
- Shadcn design, black and white, elegant, sleek
- Tailwind.css, React
- Please use the playwright MCP server when making visual changes to the front-end website to check your work

## Mobile Guidelines
Design
- Use light mode, white and grey colors, neutral
- Make sure not to hardcode colors, we want to use system/Flutter available options such as theme colorScheme etc.this will make it easier for us to add different theme modes in the future
- Use Shadcn design principles, make it beautiful and minimalistic, beautiful typography, main text is black and subtitles are usually a shade darker
- Remember about proper padding, spacing between elements and styling (again get inspiration from Shadcn design principles)
- Only use colors for accent and whenever absolutely necessary
- Less is better, we want the UI and UX to be minimalistic but also user friendly, we want user to create invoices effortlessly and quickly, if you have any idea on how we can improve something and make it easier to use, feel free to discuss it with me, we focus on core feature
- Never use gray borders with shadows. Instead, use a semi-transparent outline so the bottom edge blends with the shadow and gets darker, avoiding a 'muddy' appearance. This makes the design look 'crisp'.

- Use easy_localization for all user-facing strings
- **IMPORTANT**: Never hardcode user-facing strings. Always use localization keys from `assets/translations/en.json`
- Follow the localization key structure: `category.specific_string` (e.g., `auth.sign_in`, `wishlist.create_new`, `errors.network_error`)
- When adding new features, always add corresponding strings to the translation file first
- Use `.tr()` extension on all localization keys

### Page Transitions & Native Navigation (CRITICAL)
- **ALWAYS use native transitions for all navigation**
- **Implementation**: Use the `NativePageRoute` and `NativeTransitions` utilities from `lib/common/navigation/native_page_route.dart`
- **GoRouter Integration**: All routes MUST use `NativeTransitions.page()` for native transitions
- **Modal Presentations**: Use `NativeTransitions.showNativeModalBottomSheet()` and `NativeTransitions.showNativeDialog()`
- **In-Flow Transitions**: For AnimatedSwitcher (e.g., onboarding steps), use `NativeTransitions.buildPageTransition()`
- **Platform-Specific Behavior**:
  - **iOS**: Uses `CupertinoPageTransition` with parallax effect, `showCupertinoModalPopup`, `showCupertinoDialog`
  - **Android**: Uses Material Design transitions with fade+slide, proper curves (fastOutSlowIn), and timing
- **Platform-Specific Timing**:
  - **iOS**: 350ms transition duration for authentic feel
  - **Android**: 300ms with Material curves for snappy performance
- **Fallback Strategy**: When platform-specific isn't available, default to iOS-like animations and styling
- **Navigation Extensions**: Use `context.pushNative()`, `context.pushReplacementNative()`, `context.pushAndRemoveUntilNative()` for manual navigation
- **Never use**: Generic Flutter transitions, `showDialog`/`showModalBottomSheet` directly, non-native page routes, or `AnimatedSwitcher` without native transition builders

### User Interface Guidelines
- **Bottom Sheets Over Dialogs**: Always use styled bottom sheets instead of dialogs for confirmations, options, and forms
- **Confirmation Pattern**: Use `ConfirmationBottomSheet.show()` with loading states and clear messaging
- **Modal Presentations**: Custom styled bottom sheets with handle bars, proper spacing, and consistent design
- **Interactive Elements**: Clear button hierarchy, proper touch targets, and loading indicators during async operations

### Native Navigation Utilities Reference
All utilities are located in `lib/common/navigation/native_page_route.dart`:

**Route Creation:**
- **NativePageRoute<T>**: Custom page route with platform-specific transitions
- **NativeTransitions.page()**: For GoRouter page builders with native transitions
- **NativeTransitions.buildPageTransition()**: For AnimatedSwitcher/in-flow transitions with platform-native animations

**Modal Presentations:**
- **NativeTransitions.showNativeModalBottomSheet()**: Platform-specific bottom sheets (Cupertino on iOS, Material on Android)
- **NativeTransitions.showNativeDialog()**: Platform-specific dialog presentations

**Navigation Extensions:**
- **context.pushNative()**: Push a new screen with native transitions
- **context.pushReplacementNative()**: Replace current screen with native transitions
- **context.pushAndRemoveUntilNative()**: Push and remove all previous routes with native transitions

**Implementation Example:**
```dart
// GoRouter route
GoRoute(
  path: '/example',
  pageBuilder: (context, state) => NativeTransitions.page(
    child: const ExampleScreen(),
    key: state.pageKey,
  ),
)

// AnimatedSwitcher (onboarding, wizards)
AnimatedSwitcher(
  duration: Platform.isIOS ? Duration(milliseconds: 350) : Duration(milliseconds: 300),
  transitionBuilder: (child, animation) {
    return NativeTransitions.buildPageTransition(
      child: child,
      animation: animation,
      secondaryAnimation: AlwaysStoppedAnimation(0.0),
      isForward: true,
    );
  },
  child: currentStepWidget,
)
```

## TODO Before Release

### Backend Setup
- **Database Migration**: Run initial schema migration on production database
- **Environment Variables**: Configure all production environment variables
- **Firebase Service Account**: Set up production Firebase service account key
- **Cloudflare R2**: Configure production R2 bucket and access keys
- **SSL/HTTPS**: Ensure all API connections use HTTPS in production

### Firebase Configuration for Production
- **Android Google Sign-in**: Generate SHA-1 fingerprint for production release key and update Firebase configuration
  - Generate release keystore: `keytool -genkey -v -keystore release-key.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000`
  - Get SHA-1 fingerprint: `keytool -list -v -keystore release-key.keystore -alias release`
  - Add SHA-1 to Firebase Project Settings > Your apps > Android app
  - Download and replace `google-services.json` file
  - Required for Google Sign-in to work in production builds

### Enhanced Onboarding System
- **Contact Book Integration**: Implement contact book access and phone number validation for friend discovery
- **Friend Finding Service**: Create backend API endpoint to match phone numbers with existing users
- **Phone Number Storage**: Add phone_number field to users table with proper indexing for fast lookups
- **Privacy Controls**: Implement user privacy settings for phone number visibility and friend discovery
- **Username Availability**: Implement real-time username availability checking during onboarding
- **Birthday & Gender Fields**: Add birthday and gender fields to user profile with proper validation
- **Notification Preferences**: Implement granular notification settings for birthdays, coupons, and discounts
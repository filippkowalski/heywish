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
- Flutter with Material Design 3
- Use easy_localization for all user-facing strings
- **IMPORTANT**: Never hardcode user-facing strings. Always use localization keys from `assets/translations/en.json`
- Follow the localization key structure: `category.specific_string` (e.g., `auth.sign_in`, `wishlist.create_new`, `errors.network_error`)
- When adding new features, always add corresponding strings to the translation file first
- Use `.tr()` extension on all localization keys

### Page Transitions (CRITICAL)
- **ALWAYS use native transitions for page navigation**
- **iOS**: Use `CupertinoPageRoute` with native iOS slide transitions
- **Android**: Use `MaterialPageRoute` with native Material transitions
- **Implementation**: Create platform-specific route builders that automatically detect platform and apply appropriate transitions
- **Default behavior**: All new pages and navigation must follow this pattern
- **Never use**: Generic routes or non-native transitions that break platform conventions

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
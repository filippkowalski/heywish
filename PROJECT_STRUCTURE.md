# Jinnie Project Structure

## Overview
Jinnie is organized as a monorepo with three main projects:

```
heywish/
├── web/                    # Next.js web application (public profiles & wishlists)
├── mobile/                 # Flutter mobile app (iOS & Android)
├── extension/              # Chrome browser extension
└── docs/                   # Project documentation
```

## Web Application (`/web`)
Next.js 14 application exposing public profiles and wishlists with reservation flows.

### Key Directories:
- `app/` - App Router routes (`/[username]`, `/w/[token]`, and landing page)
- `components/` - Shared UI primitives (shadcn-based) and feature widgets
- `lib/` - Client SDKs (e.g. REST API wrapper)
- `public/` - Static assets

### Tech Stack:
- Next.js 14 (App Router)
- TypeScript
- Tailwind CSS
- Firebase Auth
- PostgreSQL (Render)

## Mobile Application (`/mobile`)
Flutter application for iOS and Android platforms.

### Key Directories:
- `lib/` - Dart source code
  - `lib/models/` - Data models
  - `lib/services/` - API and Firebase services
  - `lib/screens/` - App screens
  - `lib/widgets/` - Reusable widgets
- `ios/` - iOS-specific configuration
- `android/` - Android-specific configuration

### Tech Stack:
- Flutter
- Firebase Auth
- HTTP/Dio for API calls

## Chrome Extension (`/extension`)
Browser extension for saving products from any website.

### Key Files:
- `manifest.json` - Extension configuration
- `src/background.js` - Background service worker
- `src/content.js` - Content script for page interaction
- `src/popup.html` - Extension popup interface

### Tech Stack:
- Vanilla JavaScript/TypeScript
- Chrome Extension Manifest V3
- Firebase Auth for authentication

## Database
PostgreSQL hosted on Render.com with the following main tables:
- `users` - User accounts (synced from Firebase)
- `wishlists` - User wishlists
- `wishes` - Individual wish items
- `friendships` - Social connections
- `activities` - Activity feed
- `notifications` - User notifications

## Authentication Flow
1. Firebase handles all authentication (anonymous, email, Google, Apple)
2. Anonymous users created automatically on first visit
3. User data synced to PostgreSQL via `/api/auth/sync`
4. All API calls require Firebase ID token verification

## Environment Variables
See `web/.env.example` for required configuration:
- Firebase credentials (client and admin)
- PostgreSQL connection string
- Cloudflare settings
- Email service API keys

## Getting Started

### Prerequisites:
- Node.js 18+
- Flutter SDK
- PostgreSQL database on Render
- Firebase project

### Setup:
1. Clone the repository
2. Set up environment variables in `web/.env.local`
3. Install dependencies:
   ```bash
   cd web && npm install
   cd ../mobile && flutter pub get
   cd ../extension && npm install
   ```
4. Run database migrations
5. Start development servers:
   ```bash
   # Web
   cd web && npm run dev
   
   # Mobile
   cd mobile && flutter run
   
   # Extension
   cd extension && npm run dev
   ```

## Deployment
- **Web**: Cloudflare Pages
- **Mobile**: App Store & Google Play
- **Extension**: Chrome Web Store
- **Database**: Render.com
- **Storage**: Cloudflare R2

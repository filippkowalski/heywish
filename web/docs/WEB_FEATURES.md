# Jinnie Web App - Feature Documentation

## Overview

The Jinnie web app provides authenticated users with full CRUD capabilities for managing wishlists and wishes, bringing feature parity with the mobile app for core functionality. Built with Next.js 15, it leverages Firebase Authentication, Edge Runtime compatibility, and seamless backend integration.

---

## 🔐 Authentication System

### Firebase Integration

**File**: `lib/firebase.client.ts`, `lib/auth/AuthContext.client.tsx`

- **Google Sign-In**: Popup-based authentication flow
- **Concurrent-Safe Token Refresh**: Prevents race conditions when multiple requests need token refresh
- **Backend Sync**: Automatically syncs user data to PostgreSQL on authentication
- **Protected Routes**: Client-side auth checks with automatic redirection

### Auth Context Features

```typescript
const { user, loading, signInWithGoogle, signOut, refreshIdToken } = useAuth();
```

- **Token Caching**: Refresh promises are cached to prevent duplicate refreshes
- **Automatic Retry**: Failed requests get one retry with refreshed token
- **User State Management**: Global auth state available throughout app

---

## 📊 Dashboard

**Route**: `/dashboard`
**File**: `app/dashboard/page.tsx`

### Features

1. **Wishlist Grid Display**
   - Responsive grid layout (1-3 columns based on screen size)
   - Cover images with fallback gradients
   - Wishlist metadata (name, description, visibility, item count)

2. **Empty State**
   - Friendly call-to-action for first-time users
   - "Create Your First Wishlist" button

3. **Loading States**
   - Skeleton loaders during data fetch
   - Shimmer effect for better UX

4. **Actions Menu**
   - Edit wishlist (opens slide-over)
   - Delete wishlist (confirmation dialog)
   - Dropdown menu on each card

---

## 📝 Wishlist Management

### Create/Edit Wishlist

**Component**: `components/wishlist/WishlistSlideOver.client.tsx`

#### Form Fields

1. **Name** (Required)
   - Max 100 characters
   - Validation: Non-empty string

2. **Description** (Optional)
   - Max 500 characters
   - Textarea with multi-line support

3. **Visibility** (Required, Default: Public)
   - **Public**: Anyone can view
   - **Friends**: Only friends can view
   - **Private**: Only you can view
   - Radio group with icons (Globe, Users, Lock)

4. **Cover Image** (Optional)
   - Drag-and-drop upload
   - Preview with remove button
   - Compression to 1920x1080, 85% quality
   - Direct upload to Cloudflare R2
   - Max 5MB file size

#### Features

- **React Hook Form**: Form state management
- **Zod Validation**: Type-safe schema validation
- **Optimistic Updates**: SWR mutate for instant UI feedback
- **Loading States**: Button shows spinner during submission
- **Error Handling**: Toast notifications for user feedback

### Delete Wishlist

**Component**: `components/wishlist/DeleteWishlistDialog.client.tsx`

- **Confirmation Dialog**: AlertDialog from Radix UI
- **Item Count Warning**: Shows how many wishes will be deleted
- **Destructive Action**: Red button to emphasize permanence
- **Loading State**: Prevents double-submission

---

## 🎁 Wish Management

### Add/Edit Wish

**Component**: `components/wish/WishSlideOver.client.tsx`

#### Form Fields

1. **Product URL** (Optional)
   - Paste button for easy input
   - Auto-scraping with debounce (800ms)
   - Loading indicator during scrape
   - Success toast when metadata loaded

2. **Title** (Required)
   - Max 200 characters
   - Auto-filled from URL scraping

3. **Description** (Optional)
   - Max 1000 characters
   - Auto-filled from URL scraping

4. **Price** (Optional)
   - Number input with decimal support
   - Auto-filled from URL scraping

5. **Currency** (Required, Default: USD)
   - Searchable dropdown with 34 currencies
   - Flag icons + currency codes
   - Auto-filled from URL scraping

6. **Product Image** (Optional)
   - Square aspect ratio (1:1)
   - Compression to 1024x1024, 85% quality
   - Auto-filled from URL scraping
   - Manual upload override

#### URL Scraping

- **Debounced**: 800ms delay prevents excessive requests
- **Auto-Fill**: Populates title, description, price, currency, image
- **Source Attribution**: Toast shows which site metadata came from
- **Silent Failure**: Errors don't block form submission
- **Paste Detection**: Triggers scraping on paste event

#### Supported Metadata Sources

The backend URL scraper extracts metadata from:
- Open Graph tags
- Twitter Card tags
- Schema.org structured data
- Common e-commerce platforms (Amazon, eBay, etc.)

### Delete Wish

**Component**: `components/wish/DeleteWishDialog.client.tsx`

- Confirmation dialog with wish title
- Immediate deletion (no undo)
- SWR cache invalidation for instant UI update

---

## 🌍 Public Profile Enhancements

### Ownership Detection

**Component**: `components/profile/ProfileOwnershipWrapper.client.tsx`
**Route**: `/[username]`

#### Owner View

When viewing your own profile:

1. **Owner Actions Bar**
   - Appears above profile content
   - Shows "You're viewing your own profile"
   - "New Wishlist" button for quick creation

2. **Management UI**
   - Create wishlists directly from public profile
   - Edit/delete capabilities (modals open on click)
   - Page refresh after mutations to show updates

#### Visitor View

When viewing someone else's profile:
- Standard public view
- No management UI visible
- Reservation functionality (not yet implemented in web)

---

## 🖼️ Image Management

### ImageUploader Component

**File**: `components/form/ImageUploader.tsx`

#### Features

1. **Drag & Drop**
   - Visual feedback on drag enter
   - Highlight border on drag over
   - Multiple file handling (first file selected)

2. **File Validation**
   - Type checking (image/* only)
   - Size limit enforcement (default 5MB)
   - User-friendly error messages

3. **Compression**
   - Browser-side compression using `browser-image-compression`
   - Configurable max dimensions
   - Quality settings (85% default)

4. **Upload Flow**
   - Get presigned URL from backend
   - Direct PUT to Cloudflare R2
   - Progress indicator (simulated 0-90%, then 100% on complete)

5. **Preview**
   - Aspect ratio enforcement (video/square/auto)
   - Remove button for clearing image
   - Responsive sizing

### R2 Upload Utility

**File**: `lib/utils/upload.ts`

```typescript
uploadToR2(file, getPresignedUrl)
```

- Requests presigned URL from backend
- Uploads directly to R2 (not through backend)
- Returns public CDN URL
- Error handling with meaningful messages

---

## 💱 Currency System

### CurrencySelect Component

**File**: `components/form/CurrencySelect.tsx`
**Data**: `lib/currencies.ts`

#### Supported Currencies (34 total)

- **Major**: USD, EUR, GBP, CAD, AUD, CHF, JPY, CNY
- **Asia-Pacific**: INR, KRW, SGD, HKD, THB, IDR, MYR, PHP
- **Europe**: NOK, SEK, DKK, PLN, CZK, HUF
- **Americas**: BRL, MXN, CLP, ARS, COP
- **Middle East/Africa**: AED, SAR, ILS, TRY, ZAR
- **Europe (cont.)**: RUB

#### Features

- **Search**: Filter by code or name
- **Flag Icons**: Visual currency identification
- **Symbol Display**: Shows currency symbol in list
- **Keyboard Navigation**: Full accessibility support

---

## 🔗 URL Input Component

**File**: `components/form/UrlInput.tsx`

### Features

1. **Paste Button**
   - Clipboard API integration
   - "Pasted" confirmation (2s timeout)
   - Icon animation (Clipboard → Check)

2. **Auto-Detection**
   - onPaste event triggers callback
   - Debounced scraping integration
   - Loading indicator during processing

3. **Validation**
   - URL format checking via Zod
   - Real-time feedback
   - Error messages below input

---

## 📋 Form Validation

### Zod Schemas

**File**: `lib/utils/validation.ts`

#### Wishlist Schema

```typescript
{
  name: string (1-100 chars, required)
  description: string (0-500 chars, optional)
  visibility: enum ['public', 'friends', 'private'] (required)
  coverImageUrl: url string (optional)
}
```

#### Wish Schema

```typescript
{
  wishlistId: uuid string (optional)
  title: string (1-200 chars, required)
  description: string (0-1000 chars, optional)
  url: url string (optional)
  price: positive number (optional)
  currency: 3-char string (required)
  images: array of url strings (optional)
}
```

### React Hook Form Integration

- **Resolver**: `zodResolver()` for automatic validation
- **Error Display**: Per-field error messages
- **Submit Handling**: Prevents invalid submissions
- **Type Safety**: TypeScript inference from Zod schemas

---

## 🎨 UI Components

### Slide-Over Panel

**File**: `components/ui/slide-over.client.tsx`

- **Desktop**: Slides in from right (400-800px wide)
- **Mobile**: Full-screen modal
- **Features**:
  - Backdrop overlay with click-to-close
  - Close button (X icon)
  - Escape key handler
  - Body scroll lock when open
  - Smooth animations (300ms)

### VisibilityRadioGroup

**File**: `components/form/VisibilityRadioGroup.tsx`

- **Options**: Public / Friends / Private
- **Icons**: Eye / Users / Lock
- **Layout**: Vertical stack with full-width cards
- **Selection**: Border highlight + background color
- **Accessibility**: Proper ARIA labels and keyboard navigation

---

## 🔄 Data Fetching & Caching

### SWR Configuration

```typescript
useSWR(user ? '/wishlists' : null, () => api.getMyWishlists())
```

#### Features

1. **Conditional Fetching**: Only fetches when user is authenticated
2. **Auto-Revalidation**: Refreshes on window focus
3. **Cache Management**: In-memory cache with deduplication
4. **Optimistic Updates**: `mutate()` for instant UI feedback
5. **Error Handling**: Automatic retries with exponential backoff

### API Hook Pattern

**File**: `lib/hooks/useApiAuth.ts`

- Returns callbacks instead of direct API calls
- All requests include Firebase ID token
- Automatic 401 handling with token refresh
- Error messages propagate to UI via toast

---

## 🚀 Performance Optimizations

### Image Compression

**File**: `lib/utils/imageCompression.ts`

- **Wishlist Covers**: 1920x1080, 85% quality
- **Wish Images**: 1024x1024, 85% quality
- **Browser-Side**: No server processing required
- **Web Worker**: Non-blocking UI during compression

### Debouncing

- **URL Scraping**: 800ms debounce prevents excessive requests
- **Search Inputs**: 300ms debounce for real-time search
- **Form Validation**: Immediate feedback without lag

### Code Splitting

- **Client Components**: `'use client'` directive for proper splitting
- **Lazy Loading**: Components loaded on-demand
- **Chunking**: Shared dependencies in common chunks

---

## 🛡️ Error Handling

### Toast Notifications

**Library**: Sonner (Shadcn toast)

#### Usage Patterns

```typescript
toast.success('Wishlist created successfully');
toast.error('Failed to upload image');
toast('✨ Product details loaded from Amazon!');
```

#### Features

- **Auto-Dismiss**: 5-second timeout
- **Action Buttons**: Can include undo/retry actions
- **Position**: Top-right corner
- **Stacking**: Multiple toasts stack vertically
- **Animations**: Smooth enter/exit transitions

### Form Errors

- **Inline Validation**: Below each field
- **Submit Blocking**: Disabled button when invalid
- **Error Messages**: User-friendly, actionable text
- **Field Highlighting**: Red border + error text

### API Errors

- **Token Refresh**: Automatic retry on 401
- **Network Errors**: Toast with retry option
- **Validation Errors**: Parsed from backend response
- **Fallback Messages**: Generic error if parsing fails

---

## 🔒 Security Considerations

### Authentication

- **Firebase ID Tokens**: Short-lived, automatically refreshed
- **HTTPS Only**: All backend communication encrypted
- **No Token Storage**: Tokens kept in memory only
- **Concurrent Protection**: Cached refresh promises prevent race conditions

### Input Sanitization

- **Zod Validation**: Server-side validation mirrored on client
- **URL Validation**: Format checking before scraping
- **File Validation**: Type and size checks before upload
- **XSS Protection**: React's built-in escaping

### CORS & CSP

- **Edge Runtime**: Cloudflare Pages handles CORS
- **R2 Presigned URLs**: Time-limited upload permissions
- **No Credentials**: Tokens in Authorization header, not cookies

---

## 📱 Responsive Design

### Breakpoints

- **Mobile**: < 640px (sm)
- **Tablet**: 640px - 1024px (md)
- **Desktop**: > 1024px (lg, xl)

### Adaptations

1. **Dashboard Grid**: 1 column → 2 columns → 3 columns
2. **Slide-Overs**: Full screen → 600px width → 800px width
3. **Forms**: Stacked inputs → 2-column layout (price/currency)
4. **Navigation**: Hamburger menu → Full header
5. **Typography**: Scaled font sizes based on viewport

---

## 🏗️ Architecture Decisions

### Server vs Client Components

**Server Components** (RSC):
- Public profile pages
- Wishlist detail pages
- Static content pages
- SEO-critical pages

**Client Components**:
- Dashboard
- Forms & modals
- Auth-dependent UI
- Interactive widgets

### Why This Split?

1. **SEO**: Public pages rendered on server for crawlers
2. **Performance**: Static pages serve fast without hydration
3. **Auth**: Client components access Firebase auth state
4. **Hooks**: React hooks only work in client components

### Edge Runtime Compatibility

- **No Node.js APIs**: All code works in Cloudflare Workers
- **SSR-Safe**: Public API has no auth dependencies
- **Build Process**: `@cloudflare/next-on-pages` for deployment
- **Environment Variables**: `NEXT_PUBLIC_*` for client-side access

---

## 🧪 Testing Recommendations

### Manual Testing Checklist

1. **Authentication**
   - [ ] Google sign-in opens popup
   - [ ] User data syncs to backend
   - [ ] Token refresh handles 401s
   - [ ] Sign-out clears session

2. **Wishlist CRUD**
   - [ ] Create wishlist with all fields
   - [ ] Edit wishlist updates correctly
   - [ ] Delete shows confirmation
   - [ ] Cover image uploads successfully

3. **Wish CRUD**
   - [ ] URL scraping auto-fills fields
   - [ ] Create wish with manual input
   - [ ] Edit wish preserves data
   - [ ] Delete removes wish

4. **Ownership**
   - [ ] Own profile shows management bar
   - [ ] Other profiles hide management UI
   - [ ] Create button works on public profile

5. **Responsive**
   - [ ] Mobile layout correct (< 640px)
   - [ ] Tablet layout correct (640-1024px)
   - [ ] Desktop layout correct (> 1024px)

### Automated Testing

Currently not implemented. Future recommendations:

- **Unit Tests**: Jest for utilities (validation, compression, etc.)
- **Integration Tests**: Playwright for auth flows
- **E2E Tests**: Playwright for full user journeys
- **Visual Regression**: Percy or Chromatic for UI changes

---

## 🚀 Deployment

### Build Process

```bash
npm run pages:build
```

1. Next.js builds app
2. `@cloudflare/next-on-pages` adapts for Edge Runtime
3. Output to `.vercel/output/static`
4. Ready for Cloudflare Pages deployment

### Environment Variables (Production)

Required in Cloudflare Pages dashboard:

```
NEXT_PUBLIC_API_BASE_URL=https://openai-rewrite.onrender.com/jinnie/v1
NEXT_PUBLIC_FIREBASE_API_KEY=<your-key>
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=<your-domain>
NEXT_PUBLIC_FIREBASE_PROJECT_ID=<your-project-id>
NEXT_PUBLIC_FIREBASE_APP_ID=<your-app-id>
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=<your-bucket>
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=<your-sender-id>
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=<your-measurement-id>
```

### Deployment Steps

1. Push to GitHub (main branch)
2. Cloudflare Pages auto-builds
3. Preview deploy for PRs
4. Production deploy on merge to main

---

## 📚 Additional Resources

- **Next.js 15 Docs**: https://nextjs.org/docs
- **Firebase Auth**: https://firebase.google.com/docs/auth
- **Shadcn UI**: https://ui.shadcn.com
- **Zod Validation**: https://zod.dev
- **SWR**: https://swr.vercel.app
- **Cloudflare Pages**: https://pages.cloudflare.com

---

## 🔮 Future Enhancements

### Planned Features

1. **Wish Management on Public Pages**
   - Add/edit/delete wishes from public wishlist view (owner only)
   - Inline editing without modals

2. **Reservation System (Web)**
   - Reserve wishes on public wishlists
   - Email notifications for reservations

3. **Real-Time Updates**
   - WebSocket integration for live updates
   - Collaborative editing indicators

4. **Advanced Search**
   - Full-text search across wishlists/wishes
   - Filters by price, currency, status

5. **Social Features**
   - Friends list management
   - Activity feed
   - Comments on wishes

6. **Analytics**
   - View counts for wishlists
   - Most-viewed wishes
   - Engagement metrics

---

**Last Updated**: October 30, 2025
**Version**: 1.0.0
**Maintainer**: Claude (Implementation Assistant)

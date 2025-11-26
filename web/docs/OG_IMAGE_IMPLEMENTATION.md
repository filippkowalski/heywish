# Dynamic OG Image Implementation

This document describes the Dynamic Open Graph image generation system for Jinnie.co user profiles.

## Overview

When users share their Jinnie profile links on social media (Twitter, Facebook, LinkedIn, iMessage, etc.), a personalized preview image is generated showing:
- User's avatar (or initials fallback)
- First 3 wishlist item images as floating "thought bubbles"
- Custom branding and messaging

## File Locations

| File | Purpose |
|------|---------|
| `web/app/api/og/profile/[username]/route.tsx` | Main OG image generation API route |
| `web/app/[username]/page.tsx` | Profile page with metadata pointing to OG API |
| `web/public/og/og-background.jpg` | Background image (colorful gradient) |

## Architecture

### Technology Stack
- **`next/og` (ImageResponse)**: Built into Next.js 15, uses Satori to convert JSX → SVG → PNG
- **Edge Runtime**: Required for Cloudflare Pages compatibility
- **HTTP Caching**: Aggressive caching to prevent database overload

### Request Flow
```
Social Media Crawler → GET /api/og/profile/[username]
                            ↓
                    Check Cloudflare CDN Cache
                            ↓ (cache miss)
                    Fetch user profile from API
                            ↓
                    Generate 1200x630 PNG image
                            ↓
                    Return with cache headers
                            ↓
                    Cloudflare CDN caches for 24h
```

## Design Specifications

### Canvas Size
- **Width**: 1200px
- **Height**: 630px (standard OG image dimensions)

### Layout Elements

#### Background
- Colorful gradient image (`/og/og-background.jpg`)
- Blue → Purple → Pink → Peach gradient
- With gradient fallback: `linear-gradient(135deg, #FFF5EE 0%, #FFE4D6 50%, #FFDAB9 100%)`

#### Branding (Top Left)
- Position: `top: 32px, left: 40px`
- Text: "Jinnie.co" (28px, bold) + "✨" emoji (24px)
- Color: `#1a1a1a`

#### Avatar & User Info (Bottom Left)
- **Avatar Circle**:
  - Size: 180px × 180px
  - Position: `bottom: 50px, left: 70px`
  - Border: 5px solid white
  - Shadow: `0 12px 32px rgba(0,0,0,0.18)`
  - Fallback: Purple circle (`#6366F1`) with initials (64px, white, bold)

- **Username**:
  - Format: `@username`
  - Font: 32px, bold, `#1a1a1a`
  - Position: 16px below avatar

- **Wish Count**:
  - Format: `X wishes` (or `1 wish` for singular)
  - Font: 20px, medium weight, `#555`
  - Position: 4px below username

#### Thought Bubble Connector
- Position: `bottom: 280px, left: 240px`
- Three ascending dots (18px, 28px, 40px)
- White with shadow: `0 4px 12px rgba(0,0,0,0.12)`
- Creates visual connection between avatar and floating bubbles

#### Floating Wish Bubbles (When User Has Items)
Three circular image bubbles with varying sizes and positions:

| Bubble | Size | Position | Rotation | Border |
|--------|------|----------|----------|--------|
| 1 (largest) | 230px | top: 80, left: 480 | -4deg | 5px white |
| 2 (smallest) | 175px | top: 60, left: 720 | 6deg | 4px white |
| 3 (medium) | 200px | top: 300, left: 620 | 3deg | 4px white |

All bubbles have:
- Circular shape (`borderRadius: 50%`)
- White border
- Shadow for depth
- `objectFit: cover` for images

#### Empty State (No Wish Images)
- Single white circle (220px) at `top: 120px, right: 200px`
- Contains cute gift box icon (div-based, Satori-compatible)
- Text: "Wishes coming soon!" (16px, gray)

## Caching Strategy

### HTTP Headers
```
Cache-Control: public, s-maxage=86400, stale-while-revalidate=604800
```

- **s-maxage=86400**: CDN caches for 24 hours
- **stale-while-revalidate=604800**: Serve stale content for up to 7 days while revalidating in background

### Benefits
1. First request per username hits the database
2. Subsequent requests served from Cloudflare CDN edge
3. No database load from viral shares
4. Automatic background refresh after 24 hours

## Edge Cases Handled

### Profile Not Found
- Returns 302 redirect to static `/og-image.png`
- No database query needed for invalid usernames

### Private Profile
- Returns 302 redirect to static `/og-image.png`
- Respects user privacy settings

### No Avatar
- Shows purple circle with user initials
- Initials extracted from username (first 2 letters)
- Single letter usernames show that letter capitalized

### No Wish Images
- Shows gift box icon instead of floating bubbles
- "Wishes coming soon!" message

### API Errors
- Caught in try/catch
- Falls back to static OG image
- Errors logged to console

## Metadata Configuration

The profile page (`web/app/[username]/page.tsx`) generates metadata:

```typescript
const title = `The official wishlist of ${displayName} ✨`;
const description = itemCount > 0
  ? `Help me make some wishes come true! Check out my list of ${itemCount} items.`
  : `Help me make some wishes come true! Check out my wishlist on Jinnie.`;

const ogImages = [{
  url: `${siteUrl}/api/og/profile/${username}`,
  width: 1200,
  height: 630,
  alt: `${displayName}'s wishlist on Jinnie`,
}];
```

## Local Development

### Running Locally
```bash
cd web
npm run dev
# Visit: http://localhost:3000/api/og/profile/[username]
```

### Testing
The route auto-detects development environment and uses `localhost` for background image loading instead of production URL.

### Debugging
1. Open the API route directly in browser to see generated image
2. Check browser Network tab for any failed image loads
3. Console errors are logged on the server

## Production Deployment

### Build Verification
```bash
cd web
npm run pages:build
```

### Testing on Production
1. Deploy to Cloudflare Pages
2. Use social media debuggers to test:
   - [Facebook Sharing Debugger](https://developers.facebook.com/tools/debug/)
   - [Twitter Card Validator](https://cards-dev.twitter.com/validator)
   - [LinkedIn Post Inspector](https://www.linkedin.com/post-inspector/)

### Cache Invalidation
If you need to force-refresh a cached OG image:
1. Add query parameter: `/api/og/profile/username?v=2`
2. Or wait 24 hours for automatic refresh
3. Or purge via Cloudflare dashboard

## Modifying the Design

### Changing Colors
Edit the inline styles in `route.tsx`:
- Background gradient fallback: line ~195
- Avatar fallback color: line ~274
- Text colors: various locations

### Changing Positions
Bubble positions are absolute:
```tsx
// Bubble 1 (largest)
top: 80, left: 480

// Bubble 2 (smallest)
top: 60, left: 720

// Bubble 3 (medium)
top: 300, left: 620
```

### Changing Sizes
```tsx
// Avatar
width: 180, height: 180

// Bubbles
230px, 175px, 200px
```

### Changing Background Image
1. Place new image in `web/public/og/`
2. Update reference in `route.tsx` line ~201:
   ```tsx
   src={`${baseUrl}/og/your-new-image.jpg`}
   ```

## Technical Notes

### Satori Limitations
The `next/og` ImageResponse uses Satori which has limitations:
- **No SVG elements**: Must use div-based components
- **Limited CSS**: Not all CSS properties are supported
- **No external fonts by default**: Uses system fonts

### Why Edge Runtime?
- Required for Cloudflare Pages deployment
- Faster cold starts than serverless functions
- Global edge distribution for faster image generation

### Image Fetching
- User avatars and wish images are fetched from their original URLs
- Images must be accessible (CORS-enabled or same-origin)
- Failed image loads show broken image or fallback

## Troubleshooting

### Image Not Generating
1. Check if username exists and profile is public
2. Verify API route is accessible: `/api/og/profile/[username]`
3. Check server logs for errors

### Background Image Not Loading
1. Verify file exists: `web/public/og/og-background.jpg`
2. Check baseUrl detection in development vs production

### Wish Images Not Showing
1. Verify images are accessible (try opening URL directly)
2. Check if images have CORS headers allowing fetch
3. Verify `extractWishImages` function is finding images

### Build Failing
1. Ensure `export const runtime = 'edge';` is present
2. Check for any Node.js-specific APIs being used
3. Run `npm run pages:build` to see detailed errors

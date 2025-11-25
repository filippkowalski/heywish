import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public assets (images, fonts, etc.)
     */
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\..*|w/).*)',
  ],
};

const RESERVED_PATHS = new Set([
  'home',
  'discover',
  'profile',
  'settings',
  'onboarding',
  'privacy',
  'terms',
  'dashboard',
  'docs',
  'documentation',
  'verify-reservation',
  'delete-account',
  'affiliate-disclosure',
  'add-wish',
  'browse',
  'gift-guides',
  'inspo',
]);

export function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;

  // Remove leading/trailing slashes and split by slash
  const segments = pathname.split('/').filter(s => s.length > 0);

  // If there are 3 or more segments, this might be a broken wishlist URL
  // Example: /sassbot/christmas/hanukkah (3 segments)
  // Expected format: /sassbot/christmas-hanukkah (2 segments)
  if (segments.length >= 3) {
    const username = segments[0];

    // Don't redirect reserved paths
    if (!RESERVED_PATHS.has(username.toLowerCase())) {
      // Check if this looks like a user profile pattern (not starting with @)
      // Redirect to the user profile page
      const profileUrl = new URL(`/${username}`, request.url);

      console.log(`[Middleware] Redirecting broken wishlist URL ${pathname} -> /${username}`);

      return NextResponse.redirect(profileUrl, 301); // Permanent redirect
    }
  }

  return NextResponse.next();
}

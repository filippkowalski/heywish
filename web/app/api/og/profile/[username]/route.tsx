import { ImageResponse } from 'next/og';
import { api } from '@/lib/api';

export const runtime = 'edge';
export const revalidate = 0;

// OG Image dimensions
const WIDTH = 1200;
const HEIGHT = 630;

// Cache headers for Cloudflare CDN
const CACHE_HEADERS = {
  'Cache-Control': 'public, s-maxage=86400, stale-while-revalidate=604800',
};

// Site URL for assets
const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://jinnie.co';

// Helper to get initials from username
function getInitials(username: string): string {
  const cleaned = username.replace(/[^a-zA-Z]/g, '');
  if (cleaned.length === 0) return 'U';
  if (cleaned.length === 1) return cleaned.toUpperCase();
  return cleaned.slice(0, 2).toUpperCase();
}

// Helper to extract first N wish images from all wishlists
function extractWishImages(wishlists: Array<{ wishes?: Array<{ images?: string[] }> }>, limit: number = 3): string[] {
  const images: string[] = [];

  for (const wishlist of wishlists) {
    if (!wishlist.wishes) continue;
    for (const wish of wishlist.wishes) {
      if (wish.images && wish.images.length > 0) {
        images.push(wish.images[0]);
        if (images.length >= limit) return images;
      }
    }
  }

  return images;
}

// Gift box component using div elements (Satori-compatible)
function GiftBoxIcon() {
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {/* Ribbon bow */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          marginBottom: -8,
          zIndex: 1,
        }}
      >
        <div
          style={{
            width: 24,
            height: 24,
            borderRadius: '50%',
            background: '#FF6B6B',
            border: '3px solid #E55555',
          }}
        />
        <div
          style={{
            width: 16,
            height: 16,
            borderRadius: '50%',
            background: '#FFD93D',
            margin: '0 -4px',
            zIndex: 2,
          }}
        />
        <div
          style={{
            width: 24,
            height: 24,
            borderRadius: '50%',
            background: '#FF6B6B',
            border: '3px solid #E55555',
          }}
        />
      </div>
      {/* Box lid */}
      <div
        style={{
          width: 100,
          height: 24,
          background: '#FF9CAA',
          borderRadius: 8,
          border: '3px solid #E88D9B',
          display: 'flex',
        }}
      />
      {/* Box body */}
      <div
        style={{
          width: 90,
          height: 60,
          background: '#FFB6C1',
          borderRadius: '0 0 12px 12px',
          border: '3px solid #E88D9B',
          borderTop: 'none',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {/* Vertical ribbon */}
        <div
          style={{
            width: 12,
            height: '100%',
            background: '#FF6B6B',
          }}
        />
      </div>
    </div>
  );
}

export async function GET(
  request: Request,
  { params }: { params: Promise<{ username: string }> }
) {
  try {
    const { username } = await params;

    // Get base URL from request for local dev, fallback to SITE_URL for production
    const url = new URL(request.url);
    const baseUrl = process.env.NODE_ENV === 'development'
      ? `${url.protocol}//${url.host}`
      : SITE_URL;

    // Fetch profile data
    let profile;
    try {
      profile = await api.getPublicProfile(username);
    } catch {
      // Profile not found - return static OG
      return new Response(null, {
        status: 302,
        headers: {
          Location: `${SITE_URL}/og-image.png`,
          ...CACHE_HEADERS,
        },
      });
    }

    // Private profile - return static OG
    if (profile.user.isProfilePublic === false) {
      return new Response(null, {
        status: 302,
        headers: {
          Location: `${SITE_URL}/og-image.png`,
          ...CACHE_HEADERS,
        },
      });
    }

    const { user, wishlists, totals } = profile;
    const wishImages = extractWishImages(wishlists, 3);
    const itemCount = totals.wishCount;
    const hasItems = wishImages.length > 0;
    const initials = getInitials(user.username);

    return new ImageResponse(
      (
        <div
          style={{
            width: WIDTH,
            height: HEIGHT,
            display: 'flex',
            position: 'relative',
            fontFamily: 'Inter, system-ui, sans-serif',
          }}
        >
          {/* Background - gradient fallback */}
          <div
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              background: 'linear-gradient(135deg, #FFF5EE 0%, #FFE4D6 50%, #FFDAB9 100%)',
            }}
          />

          {/* Background image overlay */}
          <img
            src={`${baseUrl}/og/og-background.jpg`}
            alt=""
            width={WIDTH}
            height={HEIGHT}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: WIDTH,
              height: HEIGHT,
              objectFit: 'cover',
            }}
          />

          {/* Content container */}
          <div
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              display: 'flex',
              padding: 48,
            }}
          >
            {/* Branding - Top Left */}
            <div
              style={{
                position: 'absolute',
                top: 32,
                left: 40,
                display: 'flex',
                alignItems: 'center',
                gap: 8,
              }}
            >
              <span
                style={{
                  fontSize: 28,
                  fontWeight: 700,
                  color: '#1a1a1a',
                  letterSpacing: '-0.5px',
                }}
              >
                Jinnie.co
              </span>
              <span style={{ fontSize: 24 }}>✨</span>
            </div>

            {/* Avatar and username - bottom left */}
            <div
              style={{
                position: 'absolute',
                bottom: 50,
                left: 70,
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
              }}
            >
              {/* Avatar - larger */}
              <div
                style={{
                  width: 180,
                  height: 180,
                  borderRadius: '50%',
                  border: '5px solid white',
                  boxShadow: '0 12px 32px rgba(0,0,0,0.18)',
                  overflow: 'hidden',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  background: user.avatarUrl ? 'white' : '#6366F1',
                }}
              >
                {user.avatarUrl ? (
                  <img
                    src={user.avatarUrl}
                    alt=""
                    width={180}
                    height={180}
                    style={{
                      width: '100%',
                      height: '100%',
                      objectFit: 'cover',
                    }}
                  />
                ) : (
                  <span
                    style={{
                      fontSize: 64,
                      fontWeight: 700,
                      color: 'white',
                    }}
                  >
                    {initials}
                  </span>
                )}
              </div>

              {/* Username - larger */}
              <span
                style={{
                  marginTop: 16,
                  fontSize: 32,
                  fontWeight: 700,
                  color: '#1a1a1a',
                }}
              >
                @{user.username}
              </span>

              {/* Item count - larger */}
              <span
                style={{
                  marginTop: 4,
                  fontSize: 20,
                  color: '#555',
                  fontWeight: 500,
                }}
              >
                {itemCount} {itemCount === 1 ? 'wish' : 'wishes'}
              </span>
            </div>

            {/* Thought bubble connector - diagonal from avatar to bubbles */}
            <div
              style={{
                position: 'absolute',
                bottom: 280,
                left: 240,
                display: 'flex',
                alignItems: 'center',
                gap: 20,
              }}
            >
              <div
                style={{
                  width: 18,
                  height: 18,
                  borderRadius: '50%',
                  background: 'white',
                  boxShadow: '0 4px 12px rgba(0,0,0,0.12)',
                }}
              />
              <div
                style={{
                  width: 28,
                  height: 28,
                  borderRadius: '50%',
                  background: 'white',
                  boxShadow: '0 4px 12px rgba(0,0,0,0.12)',
                  marginTop: -30,
                }}
              />
              <div
                style={{
                  width: 40,
                  height: 40,
                  borderRadius: '50%',
                  background: 'white',
                  boxShadow: '0 4px 12px rgba(0,0,0,0.12)',
                  marginTop: -60,
                }}
              />
            </div>

            {/* Floating wish bubbles - clustered together with varied sizes */}
            {hasItems ? (
              <>
                {wishImages[0] && (
                  <div
                    style={{
                      position: 'absolute',
                      top: 80,
                      left: 480,
                      width: 230,
                      height: 230,
                      borderRadius: '50%',
                      overflow: 'hidden',
                      boxShadow: '0 16px 40px rgba(0,0,0,0.18)',
                      border: '5px solid white',
                      display: 'flex',
                      transform: 'rotate(-4deg)',
                    }}
                  >
                    <img
                      src={wishImages[0]}
                      alt=""
                      width={230}
                      height={230}
                      style={{
                        width: '100%',
                        height: '100%',
                        objectFit: 'cover',
                      }}
                    />
                  </div>
                )}
                {wishImages[1] && (
                  <div
                    style={{
                      position: 'absolute',
                      top: 60,
                      left: 720,
                      width: 175,
                      height: 175,
                      borderRadius: '50%',
                      overflow: 'hidden',
                      boxShadow: '0 12px 32px rgba(0,0,0,0.15)',
                      border: '4px solid white',
                      display: 'flex',
                      transform: 'rotate(6deg)',
                    }}
                  >
                    <img
                      src={wishImages[1]}
                      alt=""
                      width={175}
                      height={175}
                      style={{
                        width: '100%',
                        height: '100%',
                        objectFit: 'cover',
                      }}
                    />
                  </div>
                )}
                {wishImages[2] && (
                  <div
                    style={{
                      position: 'absolute',
                      top: 300,
                      left: 620,
                      width: 200,
                      height: 200,
                      borderRadius: '50%',
                      overflow: 'hidden',
                      boxShadow: '0 14px 36px rgba(0,0,0,0.16)',
                      border: '4px solid white',
                      display: 'flex',
                      transform: 'rotate(3deg)',
                    }}
                  >
                    <img
                      src={wishImages[2]}
                      alt=""
                      width={200}
                      height={200}
                      style={{
                        width: '100%',
                        height: '100%',
                        objectFit: 'cover',
                      }}
                    />
                  </div>
                )}
              </>
            ) : (
              <div
                style={{
                  position: 'absolute',
                  top: 120,
                  right: 200,
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  background: 'white',
                  borderRadius: '50%',
                  width: 220,
                  height: 220,
                  boxShadow: '0 12px 32px rgba(0,0,0,0.12)',
                }}
              >
                <GiftBoxIcon />
                <span
                  style={{
                    marginTop: 12,
                    fontSize: 16,
                    color: '#888',
                    textAlign: 'center',
                  }}
                >
                  Wishes coming soon!
                </span>
              </div>
            )}
          </div>
        </div>
      ),
      {
        width: WIDTH,
        height: HEIGHT,
        headers: CACHE_HEADERS,
      }
    );
  } catch (error) {
    console.error('OG Image generation error:', error);
    // Fallback to static OG on any error
    return new Response(null, {
      status: 302,
      headers: {
        Location: `${SITE_URL}/og-image.png`,
        ...CACHE_HEADERS,
      },
    });
  }
}

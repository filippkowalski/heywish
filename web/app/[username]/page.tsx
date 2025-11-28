import { cache } from "react";
import type { Metadata } from "next";

export const runtime = 'edge';
import { notFound } from "next/navigation";
import { cookies } from "next/headers";
import { api, PublicProfileResponse } from "@/lib/api";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { WishlistGrid } from "@/components/profile/wishlist-grid";
import { ProfileOwnershipWrapper } from "@/components/profile/ProfileOwnershipWrapper.client";
import { ProfileHeaderWrapper } from "@/components/profile/profile-header-wrapper.client";
import { EmptyWishlistsState } from "@/components/profile/empty-wishlists-state.client";
import { matchesWishlistSlug } from "@/lib/slug";

const getProfile = cache(async (username: string): Promise<PublicProfileResponse | null> => {
  try {
    // Try to get Firebase ID token from cookies for authenticated requests
    const cookieStore = await cookies();
    const firebaseToken = cookieStore.get('firebaseIdToken')?.value;

    const result = await api.getPublicProfile(username, firebaseToken);
    return result;
  } catch (error: unknown) {
    const err = error as { response?: { status?: number } };
    if (err?.response?.status === 404) {
      return null;
    }
    throw error;
  }
});

export async function generateMetadata({
  params,
}: {
  params: Promise<{ username: string }>;
}): Promise<Metadata> {
  const { username } = await params;
  const profile = await getProfile(username);

  if (!profile) {
    return {
      title: "Profile not found · Jinnie.co",
      description: "The profile you are looking for does not exist or is not public on Jinnie.co.",
    };
  }

  const displayName = profile.user.fullName || `@${profile.user.username}`;
  const itemCount = profile.totals.wishCount;

  // Dynamic title and description for social sharing
  const title = `The official wishlist of ${displayName} ✨`;
  const description = itemCount > 0
    ? `Help me make some wishes come true! Check out my list of ${itemCount} ${itemCount === 1 ? 'item' : 'items'}. Surprise me or pick exactly what I need.`
    : `Help me make some wishes come true! Check out my wishlist on Jinnie. Surprise me or pick exactly what I need.`;

  const canonicalPath = `/${username}`;
  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "https://jinnie.co";

  // Dynamic OG image - points to Render backend for reliable image generation with caching
  const ogApiUrl = process.env.NEXT_PUBLIC_API_URL ?? "https://openai-rewrite.onrender.com";
  const ogImages = [
    {
      url: `${ogApiUrl}/jinnie/og/profile/${username}`,
      width: 1200,
      height: 630,
      alt: `${displayName}'s wishlist on Jinnie`,
    },
  ];

  return {
    title,
    description,
    metadataBase: new URL(siteUrl),
    openGraph: {
      url: canonicalPath,
      title,
      description,
      type: "profile",
      siteName: "Jinnie.co",
      images: ogImages,
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: ogImages.map(img => img.url),
    },
    alternates: {
      canonical: canonicalPath,
    },
  };
}

export default async function PublicProfilePage({
  params,
  searchParams,
}: {
  params: Promise<{ username: string }>;
  searchParams: Promise<{ w?: string }>;
}) {
  const { username } = await params;
  const { w: wishlistSlug } = await searchParams;
  const profile = await getProfile(username);

  if (!profile) {
    notFound();
  }

  const { user, totals, wishlists } = profile;

  // Resolve wishlist slug to ID if provided
  let initialWishlistId: string | undefined;
  if (wishlistSlug) {
    const matchedWishlist = wishlists.find(w => matchesWishlistSlug(w, wishlistSlug));
    initialWishlistId = matchedWishlist?.id;
  }

  // Check if profile is private
  if (user.isProfilePublic === false) {
    return (
      <main className="min-h-screen bg-background flex items-center justify-center p-4">
        <div className="max-w-md w-full">
          <Card className="text-center p-8">
            <div className="mb-6 flex justify-center">
              <Avatar className="h-20 w-20 rounded-xl border border-border">
                {user.avatarUrl ? (
                  <AvatarImage src={user.avatarUrl} alt={user.username} />
                ) : null}
                <AvatarFallback className="rounded-xl text-lg font-semibold">
                  {user.username.slice(0, 2).toUpperCase()}
                </AvatarFallback>
              </Avatar>
            </div>
            <CardHeader>
              <CardTitle className="text-2xl mb-2">@{user.username}</CardTitle>
              <Badge variant="secondary" className="text-xs uppercase tracking-wide mx-auto">
                Private Profile
              </Badge>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="bg-muted/50 rounded-lg p-4">
                  <div className="flex items-center justify-center gap-2 text-muted-foreground mb-2">
                    <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                    </svg>
                    <span className="font-semibold">Profile is Private</span>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    This profile is private. Only friends can see their wishlists and profile details.
                  </p>
                </div>
                <div className="space-y-3">
                  <p className="text-sm text-muted-foreground">
                    Download the Jinnie app to connect with @{user.username} and view their profile.
                  </p>
                  <div className="flex flex-col items-center gap-2 pt-2">
                    <a
                      href="https://apps.apple.com/app/id6754384455?ref=jinnie-privateprofile"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block transition-transform hover:scale-105"
                      style={{ height: '80px', display: 'flex', alignItems: 'center' }}
                    >
                      <img
                        src="/badges/app-store-badge.svg"
                        alt="Download on the App Store"
                        className="h-[54px] w-auto"
                      />
                    </a>
                    <a
                      href="https://play.google.com/store/apps/details?id=com.wishlists.gifts&ref=jinnie-privateprofile"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block transition-transform hover:scale-105"
                      style={{ height: '80px', display: 'flex', alignItems: 'center' }}
                    >
                      <img
                        src="/badges/google-play-badge.png"
                        alt="Get it on Google Play"
                        className="h-[80px] w-auto"
                      />
                    </a>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>
    );
  }

  // Get Firebase ID token to determine if user is viewing their own profile
  const cookieStore = await cookies();
  const firebaseToken = cookieStore.get('firebaseIdToken')?.value;

  // For now, we'll determine ownership client-side via ProfileOwnershipWrapper
  // The ProfileHeader will receive isOwnProfile through client-side logic
  return (
    <ProfileOwnershipWrapper userId={user.id} username={user.username} wishlists={wishlists}>
      <ProfileHeaderWrapper
        userId={user.id}
        username={user.username}
        avatarUrl={user.avatarUrl}
        bio={user.bio}
        location={user.location}
        wishlistCount={wishlists.length}
        wishCount={totals.wishCount}
      />

      <main className="min-h-screen bg-background">
        {wishlists.length === 0 ? (
          <EmptyWishlistsState username={user.username} />
        ) : (
          <WishlistGrid
            wishlists={wishlists}
            username={user.username}
            initialWishlistId={initialWishlistId}
          />
        )}
      </main>
    </ProfileOwnershipWrapper>
  );
}

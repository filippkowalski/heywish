import { cache } from "react";
import type { Metadata } from "next";
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

// Hardcoded username for the browse page
const BROWSE_USERNAME = "jinnie";

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

export async function generateMetadata(): Promise<Metadata> {
  const profile = await getProfile(BROWSE_USERNAME);

  if (!profile) {
    return {
      title: "Browse · Jinnie.co",
      description: "Browse trending wishlists and discover gift ideas on Jinnie.co.",
    };
  }

  const displayName = profile.user.fullName || `@${profile.user.username}`;

  return {
    title: "Browse · Jinnie.co",
    description: `Discover ${displayName}'s wishlists and trending gift ideas on Jinnie.co - a modern wishlist platform for sharing and finding the perfect gifts.`,
    metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? "https://jinnie.co"),
    openGraph: {
      url: "/browse",
      title: "Browse · Jinnie.co",
      description: "Discover trending wishlists and gift ideas on Jinnie.co",
      type: "website",
      siteName: "Jinnie.co",
      images: [
        {
          url: profile.user.avatarUrl || "/og-image.png",
          width: 1200,
          height: 630,
          alt: "Browse Jinnie - Discover Wishlists",
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title: "Browse · Jinnie.co",
      description: "Discover trending wishlists and gift ideas",
      images: [profile.user.avatarUrl || "/og-image.png"],
    },
    alternates: {
      canonical: "/browse",
    },
  };
}

export default async function BrowsePage() {
  const profile = await getProfile(BROWSE_USERNAME);

  if (!profile) {
    notFound();
  }

  const { user, totals, wishlists } = profile;

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
          />
        )}
      </main>
    </ProfileOwnershipWrapper>
  );
}

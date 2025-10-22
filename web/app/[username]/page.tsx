import { cache } from "react";
import type { Metadata } from "next";

export const runtime = 'edge';
import { notFound } from "next/navigation";
import { Heart, MapPin, Users, Gift, BookmarkCheck } from "lucide-react";
import { api, PublicProfileResponse } from "@/lib/api";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { WishlistGrid } from "@/components/profile/wishlist-grid";

const getProfile = cache(async (username: string): Promise<PublicProfileResponse | null> => {
  try {
    console.log('[Server] Fetching profile for username:', username);
    console.log('[Server] API Base URL:', process.env.NEXT_PUBLIC_API_BASE_URL);
    const result = await api.getPublicProfile(username);
    console.log('[Server] Profile fetched successfully for:', username);
    return result;
  } catch (error: unknown) {
    console.error('[Server] Error fetching profile for:', username, error);
    const err = error as { response?: { status?: number } };
    if (err?.response?.status === 404) {
      console.log('[Server] Profile not found (404) for:', username);
      return null;
    }
    console.error('[Server] Throwing error for username:', username);
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
      title: "Profile not found · Jinnie",
      description: "The profile you are looking for does not exist or is not public on Jinnie.",
    };
  }

  const displayName = profile.user.fullName?.trim() || `@${profile.user.username}`;
  const description = profile.user.bio
    ? profile.user.bio
    : `Browse public wishlists shared by ${displayName} on Jinnie.`;
  const canonicalPath = `/${profile.user.username}`;

  return {
    title: `${displayName} • Jinnie`,
    description,
    metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? "https://jinnie.co"),
    openGraph: {
      url: canonicalPath,
      title: `${displayName} • Jinnie`,
      description,
      type: "profile",
      siteName: "Jinnie",
    },
    twitter: {
      card: "summary_large_image",
      title: `${displayName} • Jinnie`,
      description,
    },
    alternates: {
      canonical: canonicalPath,
    },
  };
}

const formatNumber = (value: number) =>
  new Intl.NumberFormat("en-US", {
    notation: value >= 1000 ? "compact" : "standard",
    maximumFractionDigits: value >= 1000 ? 1 : 0,
  }).format(value);

export default async function PublicProfilePage({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const { username } = await params;
  const profile = await getProfile(username);

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
                <p className="text-sm text-muted-foreground">
                  Connect with @{user.username} on Jinnie to view their profile.
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-background">
      <header className="border-b bg-card/50">
        <div className="container mx-auto px-4 py-6 sm:py-8 md:py-10 md:px-6">
          {/* Profile Header */}
          <div className="flex flex-col gap-4 sm:gap-5">
            <div className="flex items-start gap-3 sm:gap-4">
              <Avatar className="h-16 w-16 sm:h-20 sm:w-20 rounded-xl border border-border flex-shrink-0">
                {user.avatarUrl ? (
                  <AvatarImage src={user.avatarUrl} alt={user.fullName ?? user.username} />
                ) : null}
                <AvatarFallback className="rounded-xl text-base sm:text-lg font-semibold">
                  {(user.fullName ?? user.username).slice(0, 2).toUpperCase()}
                </AvatarFallback>
              </Avatar>
              <div className="min-w-0 flex-1 space-y-1.5 sm:space-y-2">
                <div className="flex flex-wrap items-center gap-2">
                  <h1 className="truncate text-xl font-semibold sm:text-2xl md:text-3xl">
                    {user.fullName?.trim() || user.username}
                  </h1>
                  <Badge variant="secondary" className="flex-shrink-0 text-[10px] uppercase tracking-wide sm:text-xs">
                    Public
                  </Badge>
                </div>
                <p className="flex flex-wrap items-center gap-x-2 text-xs text-muted-foreground sm:text-sm">
                  <span className="truncate">@{user.username}</span>
                  {user.location ? (
                    <span className="inline-flex items-center gap-1 flex-shrink-0">
                      <MapPin className="h-3 w-3 sm:h-3.5 sm:w-3.5" />
                      <span className="truncate">{user.location}</span>
                    </span>
                  ) : null}
                </p>
              </div>
            </div>

            {/* Bio */}
            {user.bio ? (
              <p className="text-sm sm:text-base text-muted-foreground leading-relaxed">
                {user.bio}
              </p>
            ) : null}

            {/* Stats */}
            <div className="flex flex-wrap gap-x-4 gap-y-2 text-xs sm:text-sm text-muted-foreground">
              <span className="inline-flex items-center gap-1.5 sm:gap-2">
                <Gift className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-primary flex-shrink-0" />
                <span className="font-medium text-foreground">{wishlists.length}</span> wishlists
              </span>
              <span className="inline-flex items-center gap-1.5 sm:gap-2">
                <Heart className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-rose-500 flex-shrink-0" />
                <span className="font-medium text-foreground">{formatNumber(totals.wishCount)}</span> wishes
              </span>
              <span className="inline-flex items-center gap-1.5 sm:gap-2">
                <BookmarkCheck className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-emerald-500 flex-shrink-0" />
                <span className="font-medium text-foreground">{formatNumber(totals.reservedCount)}</span> reserved
              </span>
              <span className="inline-flex items-center gap-1.5 sm:gap-2">
                <Users className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-sky-500 flex-shrink-0" />
                <span className="font-medium text-foreground">{formatNumber(user.friendCount)}</span> friends
              </span>
            </div>
          </div>
        </div>
      </header>

      {wishlists.length === 0 ? (
        <section className="container mx-auto px-4 py-12 md:px-6">
          <Card className="bg-muted/40">
            <CardContent className="flex flex-col items-center gap-4 p-10 text-center">
              <Gift className="h-10 w-10 text-muted-foreground" />
              <div>
                <h2 className="text-lg font-semibold">No public wishlists yet</h2>
                <p className="text-sm text-muted-foreground">
                  Ask {user.fullName ?? user.username} to share a list from the mobile app.
                </p>
              </div>
            </CardContent>
          </Card>
        </section>
      ) : (
        <WishlistGrid wishlists={wishlists} username={user.username} />
      )}
    </main>
  );
}

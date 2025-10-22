import { cache } from "react";
import type { Metadata } from "next";

export const runtime = 'edge';
import { notFound } from "next/navigation";
import { Heart, MapPin, Users, Gift, BookmarkCheck } from "lucide-react";
import { api, PublicProfileResponse } from "@/lib/api";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { ShareButton } from "@/components/profile/share-button";
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

  return {
    title: `${displayName} · Jinnie`,
    description,
    openGraph: {
      title: `${displayName} · Jinnie`,
      description,
    },
    twitter: {
      card: "summary_large_image",
      title: `${displayName} · Jinnie`,
      description,
    },
  };
}

const formatNumber = (value: number) =>
  new Intl.NumberFormat("en-US", {
    notation: value >= 1000 ? "compact" : "standard",
    maximumFractionDigits: value >= 1000 ? 1 : 0,
  }).format(value);

function formatPrice(amount?: number, currency: string = "USD") {
  if (amount == null) return null;

  try {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency,
      maximumFractionDigits: 0,
    }).format(amount);
  } catch {
    return `$${amount}`;
  }
}

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
        <div className="container mx-auto flex flex-col gap-6 px-4 py-12 md:flex-row md:items-center md:justify-between md:px-6">
          <div className="flex items-start gap-5">
            <Avatar className="h-20 w-20 rounded-xl border border-border">
              {user.avatarUrl ? (
                <AvatarImage src={user.avatarUrl} alt={user.fullName ?? user.username} />
              ) : null}
              <AvatarFallback className="rounded-xl text-lg font-semibold">
                {(user.fullName ?? user.username).slice(0, 2).toUpperCase()}
              </AvatarFallback>
            </Avatar>
            <div className="space-y-2">
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="text-2xl font-semibold md:text-3xl">
                  {user.fullName?.trim() || user.username}
                </h1>
                <Badge variant="secondary" className="text-xs uppercase tracking-wide">
                  Public profile
                </Badge>
              </div>
              <p className="text-sm text-muted-foreground">
                @{user.username}
                {user.location ? (
                  <span className="ml-2 inline-flex items-center gap-1">
                    <MapPin className="h-3.5 w-3.5" />
                    {user.location}
                  </span>
                ) : null}
              </p>
              {user.bio ? (
                <p className="max-w-xl text-sm text-muted-foreground">{user.bio}</p>
              ) : null}

              <div className="flex flex-wrap gap-4 text-sm text-muted-foreground">
                <span className="inline-flex items-center gap-2">
                  <Gift className="h-4 w-4 text-primary" />
                  {wishlists.length} public wishlists
                </span>
                <span className="inline-flex items-center gap-2">
                  <Heart className="h-4 w-4 text-rose-500" />
                  {formatNumber(totals.wishCount)} wishes
                </span>
                <span className="inline-flex items-center gap-2">
                  <BookmarkCheck className="h-4 w-4 text-emerald-500" />
                  {formatNumber(totals.reservedCount)} reserved
                </span>
                <span className="inline-flex items-center gap-2">
                  <Users className="h-4 w-4 text-sky-500" />
                  {formatNumber(user.friendCount)} connections
                </span>
              </div>
            </div>
          </div>

          <ShareButton
            path={`/${user.username}`}
            label="Share profile"
            title={`${user.fullName ?? user.username} · Jinnie`}
            text={`Browse ${user.fullName ?? user.username}'s public wishlists on Jinnie.`}
            className="self-start"
          />
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


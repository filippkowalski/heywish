import { cache } from "react";
import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

export const runtime = 'edge';
import { notFound } from "next/navigation";
import { Heart, MapPin, Users, Gift, BookmarkCheck } from "lucide-react";
import { api, PublicProfileResponse, Wish, Wishlist } from "@/lib/api";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ShareButton } from "@/components/profile/share-button";
import { buildWishlistPath, getWishlistSlug } from "@/lib/slug";

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

const getHighlights = (wishes: Wish[] = []) =>
  wishes.filter((wish) => wish.status !== "purchased").slice(0, 3);

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

      <section className="container mx-auto px-4 py-12 md:px-6">
        {wishlists.length === 0 ? (
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
        ) : (
          <div className="grid gap-6 lg:grid-cols-2">
            {wishlists.map((wishlist) => (
              <WishlistCard key={wishlist.id} wishlist={wishlist} username={user.username} />
            ))}
          </div>
        )}
      </section>
    </main>
  );
}

function WishlistCard({ wishlist, username }: { wishlist: Wishlist; username: string }) {
  const coverImage = wishlist.coverImageUrl;
  const slug = getWishlistSlug(wishlist);
  const canonicalPath = buildWishlistPath(username, slug);
  const canView = Boolean(wishlist.shareToken);
  const sharePath = canView ? canonicalPath : "";
  const totalItems = wishlist.wishes?.length ?? wishlist.items?.length ?? wishlist.wishCount ?? 0;
  const reservedCount = wishlist.reservedCount ?? 0;
  const highlights = getHighlights(wishlist.wishes ?? wishlist.items ?? []);

  return (
    <Card className="overflow-hidden border border-border/60">
      {coverImage ? (
        <div className="relative h-36 w-full bg-muted">
          <Image
            src={coverImage}
            alt={`${wishlist.name} cover image`}
            fill
            className="object-cover"
            sizes="(min-width: 1024px) 50vw, (min-width: 768px) 60vw, 100vw"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-background via-background/60 to-transparent" />
        </div>
      ) : null}

      <CardHeader className="flex flex-col gap-2 pb-3">
        <Badge variant="outline" className="w-fit text-xs uppercase tracking-wide">
          Public
        </Badge>
        <CardTitle className="text-xl font-semibold">{wishlist.name}</CardTitle>
        {wishlist.description ? (
          <p className="text-sm text-muted-foreground line-clamp-3">{wishlist.description}</p>
        ) : null}

        <div className="flex flex-wrap gap-4 text-xs text-muted-foreground">
          <span>{totalItems} items</span>
          <span>{reservedCount} reserved</span>
          {wishlist.updatedAt ? (
            <span>
              Updated{" "}
              {new Intl.DateTimeFormat("en", {
                month: "short",
                day: "numeric",
              }).format(new Date(wishlist.updatedAt))}
            </span>
          ) : null}
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {highlights.length > 0 ? (
          <div className="space-y-3">
            {highlights.map((wish) => (
              <WishRow key={wish.id} wish={wish} />
            ))}
          </div>
        ) : (
          <div className="rounded-md border border-dashed border-border/60 px-4 py-6 text-sm text-muted-foreground">
            No featured items yet—open the wishlist to browse everything.
          </div>
        )}

        <div className="flex flex-wrap gap-2">
          {canView ? (
            <Button asChild size="sm">
              <Link href={sharePath}>View wishlist</Link>
            </Button>
          ) : (
            <Button size="sm" variant="outline" disabled>
              View wishlist
            </Button>
          )}
          <ShareButton
            path={sharePath}
            label="Copy link"
            title={`${wishlist.name} · Jinnie`}
            text={`Check out the ${wishlist.name} wishlist on Jinnie.`}
          />
        </div>
      </CardContent>
    </Card>
  );
}

function WishRow({ wish }: { wish: Wish }) {
  const price = formatPrice(wish.price, wish.currency);
  const isReserved = wish.status === "reserved";

  return (
    <div className="flex flex-col gap-2 rounded-md border border-border/50 bg-card/40 px-4 py-3 text-sm md:flex-row md:items-center md:justify-between">
      <div className="space-y-1">
        <p className="font-medium leading-tight">{wish.title}</p>
        {wish.description ? (
          <p className="text-xs text-muted-foreground line-clamp-2">{wish.description}</p>
        ) : null}
        <div className="flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
          {price ? <span>{price}</span> : null}
          {wish.url ? (
            <a
              href={wish.url}
              target="_blank"
              rel="noopener noreferrer"
              className="font-medium text-primary hover:underline"
            >
              View item
            </a>
          ) : null}
        </div>
      </div>
      <Badge variant={isReserved ? "secondary" : "outline"} className="self-start md:self-auto">
        {isReserved ? "Reserved" : "Available"}
      </Badge>
    </div>
  );
}

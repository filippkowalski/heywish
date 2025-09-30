import { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { cache } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { api, PublicProfileResponse, Wishlist, Wish } from '@/lib/api';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { ShareButton } from '@/components/profile/share-button';
import {
  Gift,
  Heart,
  Users,
  Sparkles,
  ArrowUpRight,
  MapPin,
  Calendar,
  ShieldCheck,
} from 'lucide-react';

const getProfile = cache(async (username: string): Promise<PublicProfileResponse | null> => {
  try {
    const profile = await api.getPublicProfile(username);
    return profile;
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
      title: 'Profile not found · HeyWish',
      description: 'The profile you are looking for could not be found on HeyWish.',
    };
  }

  const displayName = profile.user.fullName?.trim() || `@${profile.user.username}`;
  const description = profile.user.bio
    ? profile.user.bio
    : `Explore ${displayName}'s wishlists on HeyWish.`;

  const openGraph = {
    title: `${displayName} · HeyWish`,
    description,
  };

  return {
    title: `${displayName} · HeyWish`,
    description,
    openGraph,
    twitter: {
      card: 'summary_large_image',
      title: openGraph.title,
      description: openGraph.description,
    },
  };
}

function formatNumber(value: number) {
  const formatter = new Intl.NumberFormat('en-US', {
    notation: value >= 1000 ? 'compact' : 'standard',
    maximumFractionDigits: value >= 1000 ? 1 : 0,
  });

  return formatter.format(value);
}

function formatPrice(amount?: number, currency: string = 'USD') {
  if (amount == null) return null;

  try {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency,
      maximumFractionDigits: 0,
    }).format(amount);
  } catch {
    return `$${amount}`;
  }
}

function highlightItems(wishes: Wish[] = []) {
  return wishes
    .filter((wish) => wish.status !== 'purchased')
    .slice(0, 3);
}

function WishlistItems({ wishes }: { wishes?: Wish[] }) {
  const featured = highlightItems(wishes ?? []);

  if (featured.length === 0) {
    return (
      <div className="rounded-lg border border-dashed border-muted-foreground/20 bg-muted/20 p-4 text-sm text-muted-foreground">
        No public items yet. Check back soon!
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {featured.map((wish) => {
        const price = formatPrice(wish.price, wish.currency);
        return (
          <div
            key={wish.id}
            className="group relative overflow-hidden rounded-lg border border-muted/30 bg-card/60 p-4 transition-all hover:border-primary/30 hover:shadow-lg"
          >
            <div className="flex flex-col gap-3 sm:flex-row sm:items-start">
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <p className="text-base font-semibold leading-snug">
                    {wish.title}
                  </p>
                  {wish.priority > 7 && (
                    <Badge variant="secondary" className="bg-primary/10 text-primary">
                      Top pick
                    </Badge>
                  )}
                </div>
                {wish.description && (
                  <p className="mt-1 text-sm text-muted-foreground line-clamp-2">
                    {wish.description}
                  </p>
                )}
                <div className="mt-3 flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
                  {price && (
                    <span className="flex items-center gap-1 font-medium text-foreground">
                      <Gift className="h-3.5 w-3.5" />
                      {price}
                    </span>
                  )}
                  {wish.url && (
                    <a
                      href={wish.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1 text-xs font-medium text-primary hover:underline"
                    >
                      View item
                      <ArrowUpRight className="h-3 w-3" />
                    </a>
                  )}
                  <Badge variant={wish.status === 'reserved' ? 'secondary' : 'outline'}>
                    {wish.status === 'reserved' ? 'Reserved' : 'Available'}
                  </Badge>
                </div>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

function WishlistCard({ wishlist }: { wishlist: Wishlist }) {
  const coverImage = wishlist.coverImageUrl;
  const sharePath = wishlist.shareToken ? `/w/${wishlist.shareToken}` : '';

  return (
    <Card className="overflow-hidden border-0 bg-gradient-to-br from-card via-card to-card shadow-lg transition hover:shadow-xl">
      {coverImage && (
        <div className="relative h-40 w-full">
          <Image
            src={coverImage}
            alt={`${wishlist.name} cover`}
            fill
            className="object-cover"
            sizes="(min-width: 1024px) 33vw, (min-width: 768px) 50vw, 100vw"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-background/80 via-background/40" />
        </div>
      )}
      <CardHeader className="space-y-3">
        <div className="flex items-start justify-between gap-2">
          <div>
            <Badge variant="outline" className="mb-2 text-xs uppercase tracking-wide">
              Public
            </Badge>
            <CardTitle className="text-xl font-semibold">
              {wishlist.name}
            </CardTitle>
          </div>
          <ShareButton
            path={sharePath}
            title={`${wishlist.name} · HeyWish`}
            text={`Explore ${wishlist.name} on HeyWish`}
          />
        </div>
        {wishlist.description && (
          <p className="text-sm text-muted-foreground line-clamp-3">
            {wishlist.description}
          </p>
        )}
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="flex flex-wrap items-center gap-4 text-sm text-muted-foreground">
          <span className="inline-flex items-center gap-1">
            <Heart className="h-4 w-4 text-primary" />
            {wishlist.wishCount} wishes
          </span>
          <span className="inline-flex items-center gap-1">
            <ShieldCheck className="h-4 w-4 text-primary" />
            {wishlist.reservedCount} reserved
          </span>
        </div>
        <WishlistItems wishes={wishlist.wishes} />
        {sharePath && (
          <div className="flex flex-wrap gap-3">
            <Button asChild size="sm">
              <Link href={sharePath} prefetch>
                View wishlist
              </Link>
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

export default async function ProfilePage({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const { username } = await params;
  const profile = await getProfile(username);

  if (!profile) {
    notFound();
  }

  const { user } = profile;
  const totals = profile.totals || { wishCount: 0, reservedCount: 0 };
  const publicWishlists = profile.wishlists.filter((wishlist) => wishlist.visibility === 'public');
  const displayName = user.fullName?.trim() || user.username;
  const initials = displayName
    .split(' ')
    .map((part) => part.charAt(0))
    .join('')
    .slice(0, 2)
    .toUpperCase();
  const joinedDate = user.createdAt ? new Date(user.createdAt) : null;
  const joinedLabel = joinedDate
    ? new Intl.DateTimeFormat('en-US', { month: 'long', year: 'numeric' }).format(joinedDate)
    : null;

  const stats = [
    {
      label: 'Public wishlists',
      value: publicWishlists.length,
      icon: Gift,
    },
    {
      label: 'Wishes shared',
      value: totals.wishCount,
      icon: Heart,
    },
    {
      label: 'Friends',
      value: user.friendCount,
      icon: Users,
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/5 via-background to-background">
      <header className="border-b border-border/40 bg-background/80 backdrop-blur">
        <div className="mx-auto flex max-w-6xl flex-col gap-8 px-4 py-12 md:flex-row md:items-center md:justify-between md:py-16">
          <div className="flex flex-col gap-6 md:flex-row md:items-center">
            <div className="relative h-24 w-24 overflow-hidden rounded-3xl border border-primary/20 bg-gradient-to-br from-primary/20 via-purple-500/20 to-primary/10 shadow-lg">
              <Avatar className="h-full w-full">
                {user.avatarUrl && <AvatarImage src={user.avatarUrl} alt={displayName} />}
                <AvatarFallback className="bg-transparent text-2xl font-semibold text-primary">
                  {initials || user.username.slice(0, 2).toUpperCase()}
                </AvatarFallback>
              </Avatar>
            </div>
            <div>
              <div className="flex flex-wrap items-center gap-3">
                <h1 className="text-3xl font-bold tracking-tight md:text-4xl">
                  {displayName}
                </h1>
                <Badge variant="outline" className="text-sm">
                  @{user.username}
                </Badge>
              </div>
              {user.bio && (
                <p className="mt-3 max-w-xl text-base text-muted-foreground">
                  {user.bio}
                </p>
              )}
              <div className="mt-4 flex flex-wrap items-center gap-4 text-sm text-muted-foreground">
                {user.location && (
                  <span className="inline-flex items-center gap-1">
                    <MapPin className="h-4 w-4" />
                    {user.location}
                  </span>
                )}
                {joinedLabel && (
                  <span className="inline-flex items-center gap-1">
                    <Calendar className="h-4 w-4" />
                    Joined {joinedLabel}
                  </span>
                )}
              </div>
            </div>
          </div>
          <div className="flex flex-col items-start gap-3 sm:flex-row">
            <ShareButton
              path={`/${user.username}`}
              label="Share profile"
              title={`${displayName} · HeyWish`}
              text={`Explore ${displayName}'s wishlists on HeyWish`}
            />
            <Button
              asChild
              className="gap-2"
              size="sm"
            >
              <a href="https://heywish.com/download" target="_blank" rel="noopener noreferrer">
                <Sparkles className="h-4 w-4" />
                Get the app
              </a>
            </Button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-6xl space-y-12 px-4 py-12 md:py-16">
        <section className="grid gap-6 md:grid-cols-3">
          {stats.map((stat) => (
            <Card
              key={stat.label}
              className="border-0 bg-gradient-to-br from-primary/5 via-purple-500/5 to-primary/10 shadow-md"
            >
              <CardContent className="flex items-center gap-4 p-6">
                <div className="rounded-2xl bg-primary/10 p-3 text-primary">
                  <stat.icon className="h-6 w-6" />
                </div>
                <div>
                  <p className="text-xs uppercase tracking-wide text-muted-foreground">
                    {stat.label}
                  </p>
                  <p className="text-2xl font-semibold text-foreground">
                    {formatNumber(stat.value)}
                  </p>
                </div>
              </CardContent>
            </Card>
          ))}
        </section>

        <section className="space-y-6">
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 className="text-2xl font-semibold tracking-tight md:text-3xl">
                Public wishlists
              </h2>
              <p className="text-sm text-muted-foreground md:text-base">
                Beautiful collections your friends can browse and reserve from.
              </p>
            </div>
          </div>

          {publicWishlists.length === 0 ? (
            <Card className="border-dashed border-primary/20 bg-muted/20">
              <CardContent className="flex flex-col items-center gap-3 p-12 text-center">
                <Heart className="h-10 w-10 text-primary" />
                <h3 className="text-lg font-semibold">No public wishlists yet</h3>
                <p className="max-w-md text-sm text-muted-foreground">
                  This user hasn’t shared any wishlists publicly. Check back later or ask them to share their favorites with you!
                </p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid gap-6 md:grid-cols-2">
              {publicWishlists.map((wishlist) => (
                <WishlistCard key={wishlist.id} wishlist={wishlist} />
              ))}
            </div>
          )}
        </section>
      </main>
    </div>
  );
}

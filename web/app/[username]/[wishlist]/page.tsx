import type { Metadata } from "next";
import { redirect, notFound } from "next/navigation";
import { cache } from "react";
import { api } from "@/lib/api";

export const runtime = 'edge';
import { matchesWishlistSlug, getWishlistSlug } from "@/lib/slug";

const getProfile = cache((username: string) => api.getPublicProfile(username));

async function resolveWishlist(username: string, slugParam: string) {
  try {
    const profile = await getProfile(username);
    const wishlist = profile.wishlists.find((item) =>
      matchesWishlistSlug(item, slugParam),
    );

    if (!wishlist) {
      // Profile exists but wishlist not found - return profile for redirect
      return { profile, wishlist: null } as const;
    }

    return { profile, wishlist } as const;
  } catch (error) {
    console.error("Error fetching profile for wishlist route:", error);
    // Profile doesn't exist - return null for 404
    return null;
  }
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ username: string; wishlist: string }>;
}): Promise<Metadata> {
  const { username, wishlist: slugParam } = await params;
  const resolved = await resolveWishlist(username, slugParam);

  if (!resolved) {
    return {
      title: "Wishlist not found · Jinnie",
    };
  }

  const { profile, wishlist } = resolved;

  // Wishlist not found - return profile metadata for redirect
  if (!wishlist) {
    const ownerName = profile.user.fullName?.trim() || `@${profile.user.username}`;
    return {
      title: `${ownerName} · Jinnie`,
      description: `View ${ownerName}'s wishlists on Jinnie`,
    };
  }

  const ownerName = profile.user.fullName?.trim() || `@${profile.user.username}`;
  const usernameDisplay = `@${profile.user.username}`;

  // Enhanced SEO-friendly description
  const description = wishlist.description
    ? `${wishlist.description} | ${ownerName}'s wishlist on Jinnie.co - discover gift ideas and make gift-giving effortless.`
    : `Explore ${ownerName}'s "${wishlist.name}" wishlist on Jinnie.co - discover their favorite items, gift ideas, and more. Make gift-giving effortless with Jinnie's modern wishlist platform.`;

  const title = `${wishlist.name} - ${usernameDisplay} · Jinnie Wishlist`;
  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "https://jinnie.co";

  // Prepare OG image - prioritize wishlist cover, then user avatar, then default
  const ogImages = wishlist.coverImageUrl
    ? [
        {
          url: wishlist.coverImageUrl,
          width: 1200,
          height: 630,
          alt: `${wishlist.name} wishlist cover`,
        },
      ]
    : profile.user.avatarUrl
      ? [
          {
            url: profile.user.avatarUrl,
            width: 400,
            height: 400,
            alt: `${ownerName}'s profile picture`,
          },
        ]
      : [
          {
            url: `${siteUrl}/og-image.png`,
            width: 1200,
            height: 630,
            alt: "Jinnie - Your Modern Wishlist Platform",
          },
        ];

  return {
    title,
    description,
    metadataBase: new URL(siteUrl),
    openGraph: {
      title,
      description,
      type: "website",
      siteName: "Jinnie.co",
      images: ogImages,
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: ogImages.map(img => img.url),
    },
  };
}

export default async function WishlistBySlugPage({
  params,
}: {
  params: Promise<{ username: string; wishlist: string }>;
}) {
  const { username, wishlist: slugParam } = await params;
  const resolved = await resolveWishlist(username, slugParam);

  // User doesn't exist - show 404
  if (!resolved) {
    notFound();
  }

  const { wishlist } = resolved;

  // Wishlist not found but user exists - redirect to user profile
  if (!wishlist) {
    redirect(`/${username}`);
  }

  // Redirect to profile page with wishlist filter using slug
  const slug = getWishlistSlug({
    slug: wishlist.slug,
    name: wishlist.name,
    shareToken: wishlist.shareToken,
    id: wishlist.id,
  });
  redirect(`/${username}?w=${encodeURIComponent(slug)}`);
}

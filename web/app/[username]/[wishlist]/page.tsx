import type { Metadata } from "next";
import { redirect, notFound } from "next/navigation";
import { cache } from "react";
import { api } from "@/lib/api";

export const runtime = 'edge';
import { matchesWishlistSlug } from "@/lib/slug";

const getProfile = cache((username: string) => api.getPublicProfile(username));

async function resolveWishlist(username: string, slugParam: string) {
  try {
    const profile = await getProfile(username);
    const wishlist = profile.wishlists.find((item) =>
      matchesWishlistSlug(item, slugParam),
    );

    if (!wishlist) {
      return null;
    }

    return { profile, wishlist } as const;
  } catch (error) {
    console.error("Error fetching profile for wishlist route:", error);
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
  const ownerName = profile.user.fullName?.trim() || `@${profile.user.username}`;
  const description =
    wishlist.description ?? `Explore ${ownerName}'s wishlist on Jinnie.`;

  return {
    title: `${wishlist.name} · ${ownerName} · Jinnie`,
    description,
    openGraph: {
      title: `${wishlist.name} · ${ownerName} · Jinnie`,
      description,
    },
    twitter: {
      card: "summary_large_image",
      title: `${wishlist.name} · ${ownerName} · Jinnie`,
      description,
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

  if (!resolved) {
    notFound();
  }

  const { wishlist } = resolved;

  // Redirect to profile page with wishlist filter
  redirect(`/${username}?w=${wishlist.id}`);
}

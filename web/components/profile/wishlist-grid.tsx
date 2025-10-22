"use client";

import { useState, useMemo } from "react";
import Link from "next/link";
import Image from "next/image";
import { Gift } from "lucide-react";
import type { Wishlist, Wish } from "@/lib/api";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { WishlistFilter } from "./wishlist-filter";

interface WishlistGridProps {
  wishlists: Wishlist[];
  username: string;
}

function formatPrice(price?: number, currency?: string): string | null {
  if (price == null) return null;
  try {
    const amount = typeof price === "string" ? parseFloat(price) : price;
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: currency || "USD",
    }).format(amount);
  } catch {
    return `$${price}`;
  }
}

function slugify(value: string = ""): string {
  return value
    .toString()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/-{2,}/g, "-");
}

function getWishlistSlug(wishlist: Wishlist): string {
  if (wishlist.slug) return wishlist.slug;
  if (wishlist.name) return slugify(wishlist.name);
  if (wishlist.shareToken) return `wishlist-${wishlist.shareToken}`;
  return wishlist.id;
}

function buildWishlistPath(username: string, slug: string): string {
  return `/${username}/${slug}`;
}

interface WishPreviewCardProps {
  wish: Wish;
  wishlist: Wishlist;
  username: string;
}

function WishPreviewCard({ wish, wishlist, username }: WishPreviewCardProps) {
  const coverImage = wish.images?.[0];
  const price = formatPrice(wish.price, wish.currency);
  const isReserved = wish.status === "reserved";
  const slug = getWishlistSlug(wishlist);
  const wishlistPath = buildWishlistPath(username, slug);

  return (
    <Link
      href={wishlistPath}
      className="group block break-inside-avoid-column mb-4"
    >
      <Card className="overflow-hidden border border-border/40 transition-all hover:border-border hover:shadow-lg">
        {coverImage ? (
          <div className="relative w-full aspect-square bg-muted">
            <Image
              src={coverImage}
              alt={wish.title}
              fill
              className="object-cover"
              sizes="(min-width: 1280px) 20vw, (min-width: 1024px) 25vw, (min-width: 640px) 40vw, 90vw"
            />
            {isReserved && (
              <div className="absolute top-3 right-3">
                <Badge variant="secondary" className="bg-black/70 text-white border-0 backdrop-blur-sm text-xs px-3 py-1">
                  Reserved
                </Badge>
              </div>
            )}
          </div>
        ) : (
          <div className="relative w-full aspect-square bg-muted/30 flex items-center justify-center">
            <div className="text-center space-y-2">
              <Gift className="h-12 w-12 text-muted-foreground/30 mx-auto" />
              <p className="text-sm text-muted-foreground px-4">{wish.title}</p>
            </div>
            {isReserved && (
              <div className="absolute top-3 right-3">
                <Badge variant="secondary" className="bg-black/70 text-white border-0 backdrop-blur-sm text-xs px-3 py-1">
                  Reserved
                </Badge>
              </div>
            )}
          </div>
        )}

        <CardContent className="p-4">
          <div className="space-y-2">
            <h3 className="font-semibold text-base leading-tight line-clamp-2 group-hover:underline">
              {wish.title}
            </h3>
            {wish.description && (
              <p className="text-xs text-muted-foreground line-clamp-2">
                {wish.description}
              </p>
            )}
            <div className="flex items-center justify-between pt-1">
              {price && (
                <span className="text-sm font-medium">
                  {price}
                </span>
              )}
              <span className="text-xs text-muted-foreground">
                {wishlist.name}
              </span>
            </div>
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}

export function WishlistGrid({ wishlists, username }: WishlistGridProps) {
  const [selectedFilter, setSelectedFilter] = useState<string | null>(null);

  const filteredWishes = useMemo(() => {
    if (selectedFilter === null) {
      // Show all wishes from all wishlists
      return wishlists.flatMap((wishlist) => {
        const allWishes = wishlist.wishes ?? wishlist.items ?? [];
        return allWishes
          .filter(wish => wish.status !== 'purchased')
          .map(wish => ({ wish, wishlist }));
      });
    } else {
      // Show wishes from selected wishlist only
      const selectedWishlist = wishlists.find(w => w.id === selectedFilter);
      if (!selectedWishlist) return [];

      const allWishes = selectedWishlist.wishes ?? selectedWishlist.items ?? [];
      return allWishes
        .filter(wish => wish.status !== 'purchased')
        .map(wish => ({ wish, wishlist: selectedWishlist }));
    }
  }, [wishlists, selectedFilter]);

  return (
    <>
      <WishlistFilter
        wishlists={wishlists}
        onFilterChange={setSelectedFilter}
      />

      <div className="container mx-auto px-4 py-6 md:px-6">
        <div className="columns-1 gap-4 space-y-4 sm:columns-2 lg:columns-3 xl:columns-4">
          {filteredWishes.map(({ wish, wishlist }) => (
            <WishPreviewCard
              key={wish.id}
              wish={wish}
              wishlist={wishlist}
              username={username}
            />
          ))}
        </div>
      </div>
    </>
  );
}

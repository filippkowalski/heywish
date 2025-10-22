"use client";

import { useEffect, useMemo, useState } from "react";
import type { KeyboardEvent } from "react";
import Image from "next/image";
import { useRouter, useSearchParams } from "next/navigation";
import type { Wishlist, Wish } from "@/lib/api";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { WishDetailDialog } from "@/components/wishlist/wish-detail-dialog";
import { WishlistFilter } from "./wishlist-filter";
import { ShareButton } from "./share-button";
import { getWishlistSlug, matchesWishlistSlug } from "@/lib/slug";

interface WishlistGridProps {
  wishlists: Wishlist[];
  username: string;
  initialWishlistId?: string;
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

interface WishPreviewCardProps {
  wish: Wish;
  wishlist: Wishlist;
  onSelect: () => void;
}

function WishPreviewCard({ wish, wishlist, onSelect }: WishPreviewCardProps) {
  const coverImage = wish.images?.[0];
  const [imageFailed, setImageFailed] = useState(false);
  useEffect(() => {
    setImageFailed(false);
  }, [coverImage]);
  const price = formatPrice(wish.price, wish.currency);
  const isReserved = wish.status === "reserved";
  const handleKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      onSelect();
    }
  };
  const showImage = Boolean(coverImage && !imageFailed);

  return (
    <div className="group break-inside-avoid-column mb-4">
      <Card
        role="button"
        tabIndex={0}
        onClick={onSelect}
        onKeyDown={handleKeyDown}
        className="group/card h-full gap-0 overflow-hidden border border-border/40 bg-card p-0 shadow-sm transition-all hover:border-border hover:shadow-lg cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40"
      >
        {showImage ? (
          <div className="relative w-full aspect-[4/3] bg-muted">
            <Image
              src={coverImage!}
              alt={wish.title}
              fill
              className="object-cover"
              sizes="(min-width: 1280px) 20vw, (min-width: 1024px) 25vw, (min-width: 640px) 40vw, 90vw"
              onError={() => setImageFailed(true)}
            />
            {isReserved && (
              <div className="absolute top-3 right-3">
                <Badge variant="secondary" className="bg-black/70 text-white border-0 backdrop-blur-sm text-xs px-3 py-1">
                  Reserved
                </Badge>
              </div>
            )}
          </div>
        ) : null}

        <CardContent className={`flex flex-1 flex-col gap-3 px-4 ${showImage ? 'pb-4 pt-3' : 'py-4'}`}>
          <div className="space-y-1.5">
            <div className="flex items-start justify-between gap-2">
              <h3 className="text-sm font-semibold leading-tight line-clamp-2 group-hover/card:underline">
                {wish.title}
              </h3>
              {!showImage && isReserved ? (
                <Badge variant="secondary" className="bg-black/70 text-white border-0 px-2 py-0.5 text-[10px] uppercase flex-shrink-0">
                  Reserved
                </Badge>
              ) : null}
            </div>
            {wish.description && (
              <p className="text-xs text-muted-foreground line-clamp-2">
                {wish.description}
              </p>
            )}
          </div>
          <div className="mt-auto flex items-end justify-between gap-2">
            <span className="flex min-h-[1.25rem] items-end text-sm font-semibold text-foreground">
              {price ?? ""}
            </span>
            <span className="text-xs font-medium text-muted-foreground text-right truncate">
              {wishlist.name}
            </span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

export function WishlistGrid({ wishlists, username, initialWishlistId }: WishlistGridProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [selectedFilter, setSelectedFilter] = useState<string | null>(initialWishlistId ?? null);
  const [detailOpen, setDetailOpen] = useState(false);
  const [activePreview, setActivePreview] = useState<{ wish: Wish; wishlist: Wishlist } | null>(null);

  // Sync URL parameter with filter state
  useEffect(() => {
    const wishlistSlug = searchParams.get('w');
    if (wishlistSlug) {
      // Find wishlist by slug
      const matchedWishlist = wishlists.find(w => matchesWishlistSlug(w, wishlistSlug));
      if (matchedWishlist && matchedWishlist.id !== selectedFilter) {
        setSelectedFilter(matchedWishlist.id);
      }
    }
  }, [searchParams, wishlists, selectedFilter]);

  const handleFilterChange = (wishlistId: string | null) => {
    setSelectedFilter(wishlistId);

    // Update URL parameter with slug instead of ID
    const params = new URLSearchParams(searchParams.toString());
    if (wishlistId) {
      const wishlist = wishlists.find(w => w.id === wishlistId);
      if (wishlist) {
        const slug = getWishlistSlug({
          slug: wishlist.slug,
          name: wishlist.name,
          shareToken: wishlist.shareToken,
          id: wishlist.id,
        });
        params.set('w', slug);
      }
    } else {
      params.delete('w');
    }

    const newUrl = params.toString() ? `/${username}?${params.toString()}` : `/${username}`;
    router.push(newUrl, { scroll: false });
  };

  const selectedWishlist = useMemo(() => {
    if (!selectedFilter) return null;
    return wishlists.find((w) => w.id === selectedFilter) ?? null;
  }, [selectedFilter, wishlists]);

  const sharePath = useMemo(() => {
    if (!selectedWishlist) {
      // Share profile page when "All" is selected
      return `/${username}`;
    }
    // Share profile page with wishlist filter using slug
    const slug = getWishlistSlug({
      slug: selectedWishlist.slug,
      name: selectedWishlist.name,
      shareToken: selectedWishlist.shareToken,
      id: selectedWishlist.id,
    });
    return `/${username}?w=${encodeURIComponent(slug)}`;
  }, [selectedWishlist, username]);

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
        selectedWishlistId={selectedFilter}
        onFilterChange={handleFilterChange}
      />

      <div className="container mx-auto px-4 py-6 md:px-6">
        <div className="flex items-center justify-between gap-3 mb-4">
          <div className="flex-1" />
          <ShareButton
            path={sharePath}
            label={selectedFilter ? "Copy wishlist link" : "Copy profile link"}
            className="flex-shrink-0"
          />
        </div>
        <div className="columns-1 gap-4 sm:columns-2 lg:columns-3 xl:columns-4 2xl:columns-5">
          {filteredWishes.map(({ wish, wishlist }) => (
            <WishPreviewCard
              key={wish.id}
              wish={wish}
              wishlist={wishlist}
              onSelect={() => {
                setActivePreview({ wish, wishlist });
                setDetailOpen(true);
              }}
            />
          ))}
        </div>
      </div>
      <WishDetailDialog
        open={detailOpen}
        onOpenChange={(open) => {
          setDetailOpen(open);
          if (!open) {
            setActivePreview(null);
          }
        }}
        wish={activePreview?.wish ?? null}
      />
    </>
  );
}

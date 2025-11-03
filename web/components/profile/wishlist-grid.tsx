"use client";

import { useEffect, useMemo, useState } from "react";
import type { KeyboardEvent } from "react";
import Image from "next/image";
import { useSearchParams } from "next/navigation";
import type { Wishlist, Wish } from "@/lib/api";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { WishDetailDialog } from "@/components/wishlist/wish-detail-dialog";
import { WishlistFilter } from "./wishlist-filter";
import { ShareButton } from "./share-button";
import { useOwnership } from "./ProfileOwnershipWrapper.client";
import { getWishlistSlug, matchesWishlistSlug } from "@/lib/slug";
import { Gift, LayoutGrid, List, Pencil, Trash2 } from "lucide-react";

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
    <Card
      role="button"
      tabIndex={0}
      onClick={onSelect}
      onKeyDown={handleKeyDown}
      className="group/card flex flex-col gap-0 overflow-hidden border border-black/10 bg-card p-0 transition-all hover:border-black/20 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40 mb-3 break-inside-avoid"
    >
        {showImage ? (
          <div className="relative w-full bg-muted max-h-[400px] overflow-hidden">
            <Image
              src={coverImage!}
              alt={wish.title}
              width={600}
              height={600}
              className="w-full h-auto object-cover"
              sizes="(min-width: 1280px) 20vw, (min-width: 1024px) 25vw, (min-width: 640px) 33vw, 50vw"
              onError={() => setImageFailed(true)}
            />
            {isReserved && (
              <div className="absolute top-2 right-2">
                <Badge variant="secondary" className="bg-black/70 text-white border-0 backdrop-blur-sm text-[10px] px-2 py-0.5">
                  Reserved
                </Badge>
              </div>
            )}
          </div>
        ) : null}

        <CardContent className={`flex flex-1 flex-col gap-2 px-3 ${showImage ? 'pb-3 pt-2' : 'py-3'}`}>
          <div className="space-y-1">
            <div className="flex items-start justify-between gap-1.5">
              <h3 className="text-sm font-semibold leading-tight line-clamp-2 group-hover/card:underline">
                {wish.title}
              </h3>
              {!showImage && isReserved ? (
                <Badge variant="secondary" className="bg-black/70 text-white border-0 px-1.5 py-0.5 text-[9px] uppercase flex-shrink-0">
                  Reserved
                </Badge>
              ) : null}
            </div>
            {wish.description && (
              <p className="text-xs text-muted-foreground line-clamp-1">
                {wish.description}
              </p>
            )}
          </div>
          <div className="mt-auto flex items-end justify-between gap-1.5">
            <span className="text-sm font-semibold text-foreground">
              {price ?? ""}
            </span>
            <span className="text-[10px] font-medium text-muted-foreground text-right truncate">
              {wishlist.name}
            </span>
          </div>
        </CardContent>
      </Card>
  );
}

function WishListViewCard({ wish, wishlist, onSelect }: WishPreviewCardProps) {
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
    <Card
      role="button"
      tabIndex={0}
      onClick={onSelect}
      onKeyDown={handleKeyDown}
      className="group/card mb-3 gap-0 overflow-hidden border border-black/10 bg-card p-0 transition-all hover:border-black/20 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40"
    >
      <div className="flex gap-4 p-4">
        {showImage ? (
          <div className="relative w-24 h-24 flex-shrink-0 bg-muted rounded-md overflow-hidden">
            <Image
              src={coverImage!}
              alt={wish.title}
              fill
              className="object-cover"
              sizes="96px"
              onError={() => setImageFailed(true)}
            />
          </div>
        ) : null}

        <div className="flex-1 flex flex-col gap-2 min-w-0">
          <div className="space-y-1">
            <div className="flex items-start justify-between gap-2">
              <h3 className="text-base font-semibold leading-tight line-clamp-2 group-hover/card:underline">
                {wish.title}
              </h3>
              {isReserved && (
                <Badge variant="secondary" className="bg-black/70 text-white border-0 px-2 py-0.5 text-[10px] uppercase flex-shrink-0">
                  Reserved
                </Badge>
              )}
            </div>
            {wish.description && (
              <p className="text-sm text-muted-foreground line-clamp-2">
                {wish.description}
              </p>
            )}
          </div>
          <div className="mt-auto flex items-end justify-between gap-2">
            <span className="text-base font-semibold text-foreground">
              {price ?? ""}
            </span>
            <span className="text-xs font-medium text-muted-foreground text-right truncate">
              {wishlist.name}
            </span>
          </div>
        </div>
      </div>
    </Card>
  );
}

export function WishlistGrid({ wishlists, username, initialWishlistId }: WishlistGridProps) {
  const searchParams = useSearchParams();
  const ownership = useOwnership();
  // Auto-select first wishlist if only one exists, otherwise default to "All" (null)
  const defaultSelection = initialWishlistId ?? (wishlists.length === 1 ? wishlists[0].id : null);
  const [selectedFilter, setSelectedFilter] = useState<string | null>(defaultSelection);
  const [detailOpen, setDetailOpen] = useState(false);
  const [activePreview, setActivePreview] = useState<{ wish: Wish; wishlist: Wishlist } | null>(null);
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid");

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

    // Update URL parameter with slug instead of ID using history API for instant updates
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

    // Use window.history.pushState for instant URL update without page reload
    if (typeof window !== 'undefined') {
      window.history.pushState(null, '', newUrl);
    }
  };

  const selectedWishlist = useMemo(() => {
    if (!selectedFilter) return null;
    return wishlists.find((w) => w.id === selectedFilter) ?? null;
  }, [selectedFilter, wishlists]);

  const sharePath = useMemo(() => {
    if (!selectedWishlist) {
      // Fallback to profile page if no wishlist selected
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

  // Calculate total value by currency
  const totalValues = useMemo(() => {
    const totals: Record<string, number> = {};

    filteredWishes.forEach(({ wish }) => {
      if (wish.price != null && !isNaN(Number(wish.price))) {
        const currency = wish.currency || 'USD';
        const price = typeof wish.price === 'string' ? parseFloat(wish.price) : wish.price;
        totals[currency] = (totals[currency] || 0) + price;
      }
    });

    return totals;
  }, [filteredWishes]);

  return (
    <>
      <WishlistFilter
        wishlists={wishlists}
        selectedWishlistId={selectedFilter}
        onFilterChange={handleFilterChange}
      />

      <div className="container mx-auto px-4 py-6 md:px-6">
        <div className="flex items-center justify-between gap-2 mb-4">
          {/* View Toggle */}
          <div className="flex items-center gap-1 border border-border rounded-lg p-1 flex-shrink-0">
            <button
              onClick={() => setViewMode("grid")}
              className={`p-2 rounded transition-colors ${
                viewMode === "grid"
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground hover:text-foreground hover:bg-accent"
              }`}
              aria-label="Grid view"
            >
              <LayoutGrid className="h-4 w-4" />
            </button>
            <button
              onClick={() => setViewMode("list")}
              className={`p-2 rounded transition-colors ${
                viewMode === "list"
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground hover:text-foreground hover:bg-accent"
              }`}
              aria-label="List view"
            >
              <List className="h-4 w-4" />
            </button>
          </div>

          {/* Right side: Total Value + Share Button */}
          <div className="flex items-center gap-2 min-w-0 flex-shrink">
            {/* Total Value Display */}
            {Object.keys(totalValues).length > 0 && (
              <div className="flex items-center gap-1.5 px-2.5 py-1.5 bg-muted/50 rounded-lg border border-black/5 min-w-0">
                <span className="text-xs font-medium text-muted-foreground whitespace-nowrap">Total:</span>
                <div className="flex items-center gap-1.5 min-w-0">
                  {Object.entries(totalValues).map(([currency, total]) => (
                    <span key={currency} className="text-sm font-semibold text-foreground truncate">
                      {formatPrice(total, currency)}
                    </span>
                  ))}
                </div>
              </div>
            )}

            <ShareButton
              path={sharePath}
              label={selectedFilter ? "Copy wishlist link" : `jinnie.co/${username}`}
              className="flex-shrink-0"
            />
          </div>
        </div>

        {filteredWishes.length === 0 ? (
          <Card className="bg-muted/40">
            <CardContent className="flex flex-col items-center gap-3 p-10 text-center">
              <Gift className="h-10 w-10 text-muted-foreground" />
              <div>
                <h2 className="text-lg font-semibold">No wishes yet</h2>
                <p className="text-sm text-muted-foreground">
                  {selectedWishlist
                    ? `"${selectedWishlist.name}" is empty. ${ownership?.isOwner ? 'Add your first wish!' : 'Check back soon!'}`
                    : ownership?.isOwner ? 'Start adding wishes to your wishlists!' : 'No wishes to display yet.'}
                </p>
              </div>
            </CardContent>
          </Card>
        ) : viewMode === "grid" ? (
          <div className="columns-2 sm:columns-2 md:columns-3 lg:columns-4 xl:columns-5 gap-3">
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
        ) : (
          <div className="max-w-4xl mx-auto">
            {filteredWishes.map(({ wish, wishlist }) => (
              <WishListViewCard
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
        )}
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
        shareToken={activePreview?.wishlist.shareToken}
        footer={ownership?.isOwner && activePreview ? ({ close }) => (
          <div className="flex flex-col sm:flex-row gap-2 sm:gap-3">
            <Button
              variant="outline"
              onClick={() => {
                ownership.openEditWish(activePreview.wish, activePreview.wishlist.id);
                close();
              }}
              className="flex-1 h-11 sm:h-12 text-base font-medium gap-2"
            >
              <Pencil className="h-4 w-4" />
              Edit
            </Button>
            <Button
              variant="outline"
              onClick={() => {
                ownership.openDeleteWish(activePreview.wish);
                close();
              }}
              className="flex-1 h-11 sm:h-12 text-base font-medium gap-2 text-destructive hover:text-destructive"
            >
              <Trash2 className="h-4 w-4" />
              Delete
            </Button>
            {activePreview.wish.url && (
              <Button
                asChild
                variant="default"
                className="flex-1 h-11 sm:h-12 text-base font-medium gap-2"
              >
                <a href={activePreview.wish.url} target="_blank" rel="noopener noreferrer">
                  View details
                </a>
              </Button>
            )}
          </div>
        ) : undefined}
      />
    </>
  );
}

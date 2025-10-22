"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import type { KeyboardEvent } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter, usePathname, useSearchParams } from "next/navigation";
import { Gift } from "lucide-react";
import type { Wishlist, Wish } from "@/lib/api";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { WishDetailDialog } from "@/components/wishlist/wish-detail-dialog";
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
  onSelect: () => void;
}

function WishPreviewCard({ wish, wishlist, onSelect }: WishPreviewCardProps) {
  const coverImage = wish.images?.[0];
  const price = formatPrice(wish.price, wish.currency);
  const isReserved = wish.status === "reserved";
  const handleKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      onSelect();
    }
  };

  return (
    <div className="group break-inside-avoid-column mb-4">
      <Card
        role="button"
        tabIndex={0}
        onClick={onSelect}
        onKeyDown={handleKeyDown}
        className="group/card h-full gap-0 overflow-hidden border border-border/40 bg-card p-0 shadow-sm transition-all hover:border-border hover:shadow-lg cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40"
      >
        {coverImage ? (
          <div className="relative w-full aspect-[3/4] bg-muted">
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
          <div className="relative flex w-full items-center justify-center bg-muted/30 aspect-[3/4]">
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

        <CardContent className="flex flex-1 flex-col gap-3 px-5 pb-5 pt-4">
          <div className="space-y-2">
            <h3 className="text-base font-semibold leading-tight line-clamp-2 group-hover/card:underline">
              {wish.title}
            </h3>
            {wish.description && (
              <p className="text-xs text-muted-foreground line-clamp-2">
                {wish.description}
              </p>
            )}
          </div>
          <div className="mt-auto flex items-end justify-between gap-2 pt-4">
            <span className="flex min-h-[1.25rem] items-end text-sm font-semibold text-foreground">
              {price ?? ""}
            </span>
            <span className="text-xs font-medium text-muted-foreground text-right">
              {wishlist.name}
            </span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

export function WishlistGrid({ wishlists, username }: WishlistGridProps) {
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();

  const wishlistParam = searchParams?.get("wishlist") ?? null;

  const findWishlistByParam = useCallback(
    (param: string | null): Wishlist | null => {
      if (!param) return null;
      return (
        wishlists.find((w) => w.id === param)
        ?? wishlists.find((w) => getWishlistSlug(w) === param)
        ?? wishlists.find((w) => w.shareToken === param)
        ?? null
      );
    },
    [wishlists],
  );

  const derivedSelection = useMemo(() => {
    return findWishlistByParam(wishlistParam)?.id ?? null;
  }, [findWishlistByParam, wishlistParam]);

  const [selectedFilter, setSelectedFilter] = useState<string | null>(derivedSelection);
  const [detailOpen, setDetailOpen] = useState(false);
  const [activePreview, setActivePreview] = useState<{ wish: Wish; wishlist: Wishlist } | null>(null);

  useEffect(() => {
    if (derivedSelection !== selectedFilter) {
      setSelectedFilter(derivedSelection);
    }
  }, [derivedSelection, selectedFilter]);

  const handleFilterChange = useCallback((wishlistId: string | null) => {
    if (wishlistId === selectedFilter) return;

    if (wishlistId === null) {
      setSelectedFilter(null);
      const params = new URLSearchParams(searchParams?.toString() ?? "");
      params.delete("wishlist");
      const queryString = params.toString();
      router.replace(queryString ? `${pathname}?${queryString}` : pathname, { scroll: false });
      return;
    }

    const targetWishlist = wishlists.find((w) => w.id === wishlistId);
    if (!targetWishlist) {
      return;
    }

    setSelectedFilter(wishlistId);
    const slug = getWishlistSlug(targetWishlist);
    const params = new URLSearchParams(searchParams?.toString() ?? "");
    params.set("wishlist", slug);
    const queryString = params.toString();
    router.replace(`${pathname}?${queryString}`, { scroll: false });
  }, [pathname, router, searchParams, selectedFilter, wishlists]);

  const selectedWishlist = useMemo(() => {
    if (!selectedFilter) return null;
    return wishlists.find((w) => w.id === selectedFilter) ?? null;
  }, [selectedFilter, wishlists]);

  const sharePath = useMemo(() => {
    if (!selectedWishlist) return undefined;
    const slug = getWishlistSlug(selectedWishlist);
    return `/${username}?wishlist=${encodeURIComponent(slug)}`;
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
        sharePath={sharePath}
      />

      <div className="container mx-auto px-4 py-6 md:px-6">
        <div className="columns-1 gap-4 space-y-4 sm:columns-2 lg:columns-3 xl:columns-4">
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
        footer={({ close }) => (
          <div className="flex flex-col-reverse gap-2 sm:flex-row sm:gap-3">
            <Button
              variant="outline"
              onClick={close}
              className="flex-1 h-11 sm:h-12 text-base font-medium"
            >
              Close
            </Button>
            {activePreview ? (
              <Button asChild className="flex-1 h-11 sm:h-12 text-base font-medium">
                <Link href={buildWishlistPath(username, getWishlistSlug(activePreview.wishlist))}>
                  View wishlist
                </Link>
              </Button>
            ) : null}
          </div>
        )}
      />
    </>
  );
}

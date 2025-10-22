"use client";

import type { Wishlist } from "@/lib/api";

interface WishlistFilterProps {
  wishlists: Wishlist[];
  selectedWishlistId: string | null;
  onFilterChange: (wishlistId: string | null) => void;
}

export function WishlistFilter({
  wishlists,
  selectedWishlistId,
  onFilterChange,
}: WishlistFilterProps) {
  return (
    <div className="sticky top-0 z-20 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/80">
      <div className="container mx-auto px-4 md:px-6">
        <div className="flex items-center gap-3 py-3 overflow-x-auto scrollbar-hide">
          {/* All filter */}
          <button
            onClick={() => onFilterChange(null)}
            className={`
              flex-shrink-0 rounded-full px-3 py-1.5 text-xs font-medium transition-all sm:px-4 sm:py-2 sm:text-sm
              ${
                selectedWishlistId === null
                  ? "bg-primary text-primary-foreground shadow-sm"
                  : "bg-muted/50 border border-border/50 text-foreground hover:bg-muted active:scale-95"
              }
            `}
          >
            All
          </button>

          {/* Wishlist filters */}
          {wishlists.map((wishlist) => {
            const wishCount =
              wishlist.wishes?.length ?? wishlist.items?.length ?? wishlist.wishCount ?? 0;
            const isSelected = selectedWishlistId === wishlist.id;
            return (
              <button
                key={wishlist.id}
                onClick={() => onFilterChange(wishlist.id)}
                className={`
                  flex shrink-0 items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium transition-all sm:gap-2 sm:px-4 sm:py-2 sm:text-sm
                  ${
                    isSelected
                      ? "bg-primary text-primary-foreground shadow-sm"
                      : "bg-muted/50 border border-border/50 text-foreground hover:bg-muted active:scale-95"
                  }
                `}
              >
                <span className="max-w-[120px] truncate sm:max-w-none">{wishlist.name}</span>
                {wishCount > 0 && (
                  <span
                    className={`
                      flex-shrink-0 rounded-full px-1.5 py-0.5 text-[10px] font-semibold sm:text-xs
                      ${
                        isSelected
                          ? "bg-primary-foreground/20 text-primary-foreground"
                          : "bg-background/80 text-muted-foreground"
                      }
                    `}
                  >
                    {wishCount}
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

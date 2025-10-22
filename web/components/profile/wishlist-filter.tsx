"use client";

import { useState } from "react";
import type { Wishlist } from "@/lib/api";

interface WishlistFilterProps {
  wishlists: Wishlist[];
  onFilterChange: (wishlistId: string | null) => void;
}

export function WishlistFilter({ wishlists, onFilterChange }: WishlistFilterProps) {
  const [selectedFilter, setSelectedFilter] = useState<string | null>(null);

  const handleFilterClick = (wishlistId: string | null) => {
    setSelectedFilter(wishlistId);
    onFilterChange(wishlistId);
  };

  return (
    <div className="sticky top-0 z-10 bg-background border-b">
      <div className="overflow-x-auto scrollbar-hide">
        <div className="flex gap-2 px-4 py-3 md:px-6 min-w-max">
          {/* All filter */}
          <button
            onClick={() => handleFilterClick(null)}
            className={`
              flex-shrink-0 px-3 py-1.5 sm:px-4 sm:py-2 rounded-full text-xs sm:text-sm font-medium transition-all
              ${
                selectedFilter === null
                  ? "bg-primary text-primary-foreground shadow-sm"
                  : "bg-muted/50 border border-border/50 text-foreground hover:bg-muted active:scale-95"
              }
            `}
          >
            All
          </button>

          {/* Wishlist filters */}
          {wishlists.map((wishlist) => {
            const wishCount = wishlist.wishes?.length ?? wishlist.items?.length ?? wishlist.wishCount ?? 0;
            return (
              <button
                key={wishlist.id}
                onClick={() => handleFilterClick(wishlist.id)}
                className={`
                  flex-shrink-0 px-3 py-1.5 sm:px-4 sm:py-2 rounded-full text-xs sm:text-sm font-medium transition-all flex items-center gap-1.5 sm:gap-2
                  ${
                    selectedFilter === wishlist.id
                      ? "bg-primary text-primary-foreground shadow-sm"
                      : "bg-muted/50 border border-border/50 text-foreground hover:bg-muted active:scale-95"
                  }
                `}
              >
                <span className="truncate max-w-[120px] sm:max-w-none">{wishlist.name}</span>
                {wishCount > 0 && (
                  <span
                    className={`
                      text-[10px] sm:text-xs px-1.5 py-0.5 rounded-full font-semibold flex-shrink-0
                      ${
                        selectedFilter === wishlist.id
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

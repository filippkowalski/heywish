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
    <div className="overflow-x-auto pb-2 scrollbar-hide">
      <div className="flex gap-2 px-4 md:px-6">
        {/* All filter */}
        <button
          onClick={() => handleFilterClick(null)}
          className={`
            flex-shrink-0 px-4 py-2 rounded-lg text-sm font-medium transition-all
            ${
              selectedFilter === null
                ? "bg-primary text-primary-foreground shadow-md"
                : "bg-background border border-border text-foreground hover:bg-muted"
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
                flex-shrink-0 px-4 py-2 rounded-lg text-sm font-medium transition-all flex items-center gap-2
                ${
                  selectedFilter === wishlist.id
                    ? "bg-primary text-primary-foreground shadow-md"
                    : "bg-background border border-border text-foreground hover:bg-muted"
                }
              `}
            >
              <span>{wishlist.name}</span>
              {wishCount > 0 && (
                <span
                  className={`
                    text-xs px-1.5 py-0.5 rounded-full
                    ${
                      selectedFilter === wishlist.id
                        ? "bg-primary-foreground/20 text-primary-foreground"
                        : "bg-muted text-muted-foreground"
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
  );
}

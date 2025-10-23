"use client";

import { useEffect, useRef, useState } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
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
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(false);

  const updateScrollIndicators = () => {
    if (!scrollContainerRef.current) return;

    const { scrollLeft, scrollWidth, clientWidth } = scrollContainerRef.current;
    setCanScrollLeft(scrollLeft > 0);
    setCanScrollRight(scrollLeft < scrollWidth - clientWidth - 1);
  };

  useEffect(() => {
    const container = scrollContainerRef.current;
    if (!container) return;

    updateScrollIndicators();

    const handleScroll = () => updateScrollIndicators();
    const handleResize = () => updateScrollIndicators();

    container.addEventListener("scroll", handleScroll);
    window.addEventListener("resize", handleResize);

    return () => {
      container.removeEventListener("scroll", handleScroll);
      window.removeEventListener("resize", handleResize);
    };
  }, [wishlists]);

  const scroll = (direction: "left" | "right") => {
    if (!scrollContainerRef.current) return;

    const scrollAmount = 200;
    const newScrollLeft =
      direction === "left"
        ? scrollContainerRef.current.scrollLeft - scrollAmount
        : scrollContainerRef.current.scrollLeft + scrollAmount;

    scrollContainerRef.current.scrollTo({
      left: newScrollLeft,
      behavior: "smooth",
    });
  };

  return (
    <div className="sticky top-0 z-20 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/80">
      <div className="container mx-auto px-4 md:px-6">
        <div className="relative">
          {/* Left scroll indicator */}
          {canScrollLeft && (
            <button
              onClick={() => scroll("left")}
              className="absolute left-0 top-1/2 z-10 -translate-y-1/2 flex h-8 w-8 items-center justify-center rounded-full bg-background/95 shadow-lg border border-border/50 hover:bg-muted transition-colors"
              aria-label="Scroll left"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
          )}

          {/* Right scroll indicator */}
          {canScrollRight && (
            <button
              onClick={() => scroll("right")}
              className="absolute right-0 top-1/2 z-10 -translate-y-1/2 flex h-8 w-8 items-center justify-center rounded-full bg-background/95 shadow-lg border border-border/50 hover:bg-muted transition-colors"
              aria-label="Scroll right"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          )}

          {/* Scrollable content */}
          <div
            ref={scrollContainerRef}
            className="flex items-center gap-3 py-3 overflow-x-auto scrollbar-hide"
          >
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
    </div>
  );
}

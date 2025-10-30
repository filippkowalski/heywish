"use client";

import { useEffect, useRef, useState } from "react";
import { ChevronLeft, ChevronRight, Plus, Lock, Users } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useOwnership } from "./ProfileOwnershipWrapper.client";
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
  const ownership = useOwnership();
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

  const handleAddWish = () => {
    // Open wish form with pre-selected wishlist if one is selected
    // If "All" is selected (null), don't pre-select any wishlist
    ownership?.openNewWish(selectedWishlistId);
  };

  return (
    <>
      <div className="sticky top-0 z-20 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/80">
        <div className="container mx-auto px-4 md:px-6">
          <div className="flex items-center gap-3 relative">
            {/* Wishlist selector section */}
            <div className="flex-1 relative min-w-0">
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
            {/* All filter - only show if there are multiple wishlists */}
            {wishlists.length > 1 && (
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
            )}

            {/* Wishlist filters */}
            {wishlists.map((wishlist) => {
              const wishCount =
                wishlist.wishes?.length ?? wishlist.items?.length ?? wishlist.wishCount ?? 0;
              const isSelected = selectedWishlistId === wishlist.id;
              const showVisibilityIcon = wishlist.visibility !== 'public';

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
                  {showVisibilityIcon && (
                    wishlist.visibility === 'private' ? (
                      <Lock className="h-3 w-3 sm:h-3.5 sm:w-3.5 flex-shrink-0" />
                    ) : wishlist.visibility === 'friends' ? (
                      <Users className="h-3 w-3 sm:h-3.5 sm:w-3.5 flex-shrink-0" />
                    ) : null
                  )}
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

          {/* Owner Management Buttons */}
          {ownership?.isOwner && (
            <div className="flex items-center gap-2 flex-shrink-0">
              {/* Add Wish button - hidden on mobile (shown as FAB instead) */}
              <Button
                onClick={handleAddWish}
                size="sm"
                variant="default"
                className="hidden md:flex items-center gap-1.5"
              >
                <Plus className="h-4 w-4" />
                <span className="hidden lg:inline">Add Wish</span>
              </Button>

              {/* New Wishlist button */}
              <Button
                onClick={() => ownership.openNewWishlist()}
                size="sm"
                variant="outline"
                className="flex items-center gap-1.5"
              >
                <Plus className="h-4 w-4" />
                <span className="hidden sm:inline">New Wishlist</span>
              </Button>
            </div>
          )}
        </div>
      </div>
    </div>

    {/* Floating Action Button for mobile - outside sticky container */}
    {ownership?.isOwner && (
      <button
        onClick={handleAddWish}
        className="md:hidden fixed bottom-6 right-6 z-50 h-14 w-14 rounded-full bg-primary text-primary-foreground shadow-lg hover:shadow-xl transition-all active:scale-95 flex items-center justify-center"
        aria-label="Add wish"
      >
        <Plus className="h-6 w-6" />
      </button>
    )}
    </>
  );
}

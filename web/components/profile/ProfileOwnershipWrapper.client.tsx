'use client';

import { createContext, useContext, useState, useEffect } from 'react';
import { useAuth } from '@/lib/auth/AuthContext.client';
import { WishlistSlideOver } from '@/components/wishlist/WishlistSlideOver.client';
import { WishSlideOver } from '@/components/wish/WishSlideOver.client';
import { DeleteWishlistDialog } from '@/components/wishlist/DeleteWishlistDialog.client';
import { DeleteWishDialog } from '@/components/wish/DeleteWishDialog.client';
import { ManageWishlistsDialog } from '@/components/wishlist/ManageWishlistsDialog.client';
import type { Wishlist, Wish } from '@/lib/api';

interface ProfileOwnershipWrapperProps {
  userId: string;
  username: string;
  wishlists: Wishlist[];
  children: React.ReactNode;
}

interface OwnershipContextValue {
  isOwner: boolean;
  openNewWishlist: () => void;
  openNewWish: (wishlistId?: string | null) => void;
  openEditWish: (wish: Wish, wishlistId: string) => void;
  openDeleteWish: (wish: Wish) => void;
  openEditWishlist: (wishlist: Wishlist) => void;
  openDeleteWishlist: (wishlist: Wishlist) => void;
  openManageWishlists: () => void;
}

const OwnershipContext = createContext<OwnershipContextValue | null>(null);

export function useOwnership() {
  const context = useContext(OwnershipContext);
  return context; // Can be null if not owner
}

export function ProfileOwnershipWrapper({
  userId,
  username,
  wishlists,
  children,
}: ProfileOwnershipWrapperProps) {
  const { user, backendUser } = useAuth();
  const [showNewWishlist, setShowNewWishlist] = useState(false);
  const [showNewWish, setShowNewWish] = useState(false);
  const [newWishWishlistId, setNewWishWishlistId] = useState<string | null>(null);
  const [editingWish, setEditingWish] = useState<{ wish: Wish; wishlistId: string } | null>(null);
  const [deletingWish, setDeletingWish] = useState<Wish | null>(null);
  const [editingWishlist, setEditingWishlist] = useState<Wishlist | null>(null);
  const [deletingWishlist, setDeletingWishlist] = useState<Wishlist | null>(null);
  const [showManageWishlists, setShowManageWishlists] = useState(false);

  // Check if the logged-in user is the owner
  // Compare backend user ID (from auth context) with profile user ID
  const isOwner = backendUser?.id === userId || backendUser?.username === username;

  // Listen for custom event from site header
  useEffect(() => {
    const handleOpenManageWishlists = () => {
      if (isOwner) {
        setShowManageWishlists(true);
      }
    };

    window.addEventListener('openManageWishlists', handleOpenManageWishlists);
    return () => {
      window.removeEventListener('openManageWishlists', handleOpenManageWishlists);
    };
  }, [isOwner]);

  const ownershipValue: OwnershipContextValue = {
    isOwner,
    openNewWishlist: () => setShowNewWishlist(true),
    openNewWish: (wishlistId?: string | null) => {
      setNewWishWishlistId(wishlistId || null);
      setShowNewWish(true);
    },
    openEditWish: (wish: Wish, wishlistId: string) => setEditingWish({ wish, wishlistId }),
    openDeleteWish: (wish: Wish) => setDeletingWish(wish),
    openEditWishlist: (wishlist: Wishlist) => setEditingWishlist(wishlist),
    openDeleteWishlist: (wishlist: Wishlist) => setDeletingWishlist(wishlist),
    openManageWishlists: () => setShowManageWishlists(true),
  };

  return (
    <OwnershipContext.Provider value={ownershipValue}>
      {children}

      {/* Modals */}
      {isOwner && (
        <>
          <WishlistSlideOver
            open={showNewWishlist}
            onClose={() => setShowNewWishlist(false)}
            onSuccess={() => {
              window.location.reload();
            }}
          />

          <WishSlideOver
            open={showNewWish}
            onClose={() => {
              setShowNewWish(false);
              setNewWishWishlistId(null);
            }}
            onSuccess={() => {
              window.location.reload();
            }}
            wishlistId={newWishWishlistId || undefined}
            wishlists={wishlists}
          />

          {editingWish && (
            <WishSlideOver
              open={!!editingWish}
              onClose={() => setEditingWish(null)}
              onSuccess={() => {
                window.location.reload();
              }}
              wishlistId={editingWish.wishlistId}
              wish={editingWish.wish}
              wishlists={wishlists}
            />
          )}

          {deletingWish && (
            <DeleteWishDialog
              open={!!deletingWish}
              onOpenChange={(open) => !open && setDeletingWish(null)}
              wish={deletingWish}
              onSuccess={() => {
                window.location.reload();
              }}
            />
          )}

          {editingWishlist && (
            <WishlistSlideOver
              open={!!editingWishlist}
              onClose={() => setEditingWishlist(null)}
              onSuccess={() => {
                window.location.reload();
              }}
              wishlist={editingWishlist}
            />
          )}

          {deletingWishlist && (
            <DeleteWishlistDialog
              open={!!deletingWishlist}
              onOpenChange={(open) => !open && setDeletingWishlist(null)}
              wishlist={deletingWishlist}
              onSuccess={() => {
                window.location.reload();
              }}
            />
          )}

          <ManageWishlistsDialog
            open={showManageWishlists}
            onOpenChange={setShowManageWishlists}
            wishlists={wishlists}
            onEdit={(wishlist) => {
              setShowManageWishlists(false);
              setEditingWishlist(wishlist);
            }}
            onDelete={(wishlist) => {
              setShowManageWishlists(false);
              setDeletingWishlist(wishlist);
            }}
          />
        </>
      )}
    </OwnershipContext.Provider>
  );
}

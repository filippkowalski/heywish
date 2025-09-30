import axios from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'https://openai-rewrite.onrender.com/heywish/v1';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
    'X-API-Version': '1.0',
  },
});

// Types based on our API specification
export interface Wish {
  id: string;
  title: string;
  description?: string;
  url?: string;
  price?: number;
  currency: string;
  images?: string[];
  status: 'available' | 'reserved' | 'purchased';
  priority: number;
  quantity: number;
  notes?: string;
  reservedBy?: string;
  reservedAt?: string;
  purchasedBy?: string;
  purchasedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Wishlist {
  id: string;
  userId: string;
  name: string;
  description?: string;
  visibility: 'private' | 'friends' | 'public';
  shareToken?: string;
  coverImageUrl?: string;
  wishCount: number;
  reservedCount: number;
  createdAt: string;
  updatedAt: string;
  wishes?: Wish[];
  items?: Wish[]; // Backend returns 'items' field, map to wishes
  owner_name?: string; // For display purposes in shared wishlists
}

export interface PublicWishlistResponse {
  wishlist: Wishlist;
}

export interface PublicProfileUser {
  id: string;
  username: string;
  fullName?: string | null;
  avatarUrl?: string | null;
  bio?: string | null;
  location?: string | null;
  createdAt: string;
  updatedAt: string;
  wishlistCount: number;
  friendCount: number;
}

export interface PublicProfileResponse {
  user: PublicProfileUser;
  wishlists: Wishlist[];
  totals: {
    wishCount: number;
    reservedCount: number;
  };
}

type RawWish = {
  id: string | number;
  title: string;
  description?: string | null;
  url?: string | null;
  price?: string | number | null;
  currency?: string | null;
  images?: string[] | null;
  status: 'available' | 'reserved' | 'purchased';
  priority?: number | null;
  quantity?: number | null;
  notes?: string | null;
  reservedBy?: string | null;
  reserved_by?: string | null;
  reservedAt?: string | null;
  reserved_at?: string | null;
  purchasedBy?: string | null;
  purchased_by?: string | null;
  purchasedAt?: string | null;
  purchased_at?: string | null;
  createdAt?: string | null;
  created_at?: string | null;
  updatedAt?: string | null;
  updated_at?: string | null;
};

type RawWishlist = {
  id: string | number;
  user_id: string | number;
  name: string;
  description?: string | null;
  visibility: 'private' | 'friends' | 'public';
  share_token?: string | null;
  cover_image_url?: string | null;
  item_count?: number | string | null;
  wish_count?: number | string | null;
  reserved_count?: number | string | null;
  created_at: string;
  updated_at: string;
  items?: RawWish[] | null;
  wishes?: RawWish[] | null;
};

type RawPublicProfileUser = {
  id: string | number;
  username: string;
  full_name?: string | null;
  fullName?: string | null;
  avatar_url?: string | null;
  avatarUrl?: string | null;
  bio?: string | null;
  location?: string | null;
  created_at?: string;
  createdAt?: string;
  updated_at?: string;
  updatedAt?: string;
  wishlist_count?: number | string | null;
  wishlistCount?: number | string | null;
  friend_count?: number | string | null;
  friendCount?: number | string | null;
};

type RawProfileTotals = {
  wish_count?: number | string | null;
  wishCount?: number | string | null;
  reserved_count?: number | string | null;
  reservedCount?: number | string | null;
};

// API functions
export const api = {
  // Get public wishlist by share token
  async getPublicWishlist(shareToken: string): Promise<PublicWishlistResponse> {
    try {
      const response = await apiClient.get(`/public/wishlists/${shareToken}`);
      return response.data;
    } catch (error) {
      console.error('Error fetching public wishlist:', error);
      throw error;
    }
  },

  // Reserve a wish item
  async reserveWish(wishId: string, message?: string): Promise<void> {
    try {
      await apiClient.post(`/wishes/${wishId}/reserve`, {
        message,
        hideFromOwner: false
      });
    } catch (error) {
      console.error('Error reserving wish:', error);
      throw error;
    }
  },

  // Cancel wish reservation
  async cancelReservation(wishId: string): Promise<void> {
    try {
      await apiClient.delete(`/wishes/${wishId}/reserve`);
    } catch (error) {
      console.error('Error canceling reservation:', error);
      throw error;
    }
  },

  async getPublicProfile(username: string): Promise<PublicProfileResponse> {
    try {
      const { data } = await apiClient.get(`/public/users/${username}`);
      const payload = data as {
        user: RawPublicProfileUser;
        wishlists?: RawWishlist[];
        totals?: RawProfileTotals;
      };

      const rawWishlists = payload.wishlists ?? [];

      const normalizedWishlists: Wishlist[] = rawWishlists.map((wishlist) => ({
        id: String(wishlist.id),
        userId: String(wishlist.user_id),
        name: wishlist.name,
        description: wishlist.description ?? undefined,
        visibility: wishlist.visibility,
        shareToken: wishlist.share_token ?? undefined,
        coverImageUrl: wishlist.cover_image_url ?? undefined,
        wishCount: Number(wishlist.item_count ?? wishlist.wish_count ?? 0),
        reservedCount: Number(wishlist.reserved_count ?? 0),
        createdAt: wishlist.created_at,
        updatedAt: wishlist.updated_at,
        wishes: (wishlist.items ?? wishlist.wishes ?? []).map((wish: RawWish) => ({
          id: String(wish.id),
          title: wish.title,
          description: wish.description ?? undefined,
          url: wish.url ?? undefined,
          price: wish.price != null ? Number(wish.price) : undefined,
          currency: wish.currency ?? 'USD',
          images: wish.images ?? undefined,
          status: wish.status,
          priority: wish.priority ?? 0,
          quantity: wish.quantity ?? 1,
          notes: wish.notes ?? undefined,
          reservedBy: wish.reservedBy ?? wish.reserved_by ?? undefined,
          reservedAt: wish.reservedAt ?? wish.reserved_at ?? undefined,
          purchasedBy: wish.purchasedBy ?? wish.purchased_by ?? undefined,
          purchasedAt: wish.purchasedAt ?? wish.purchased_at ?? undefined,
          createdAt: wish.createdAt ?? wish.created_at ?? new Date().toISOString(),
          updatedAt: wish.updatedAt ?? wish.updated_at ?? new Date().toISOString(),
        })),
      }));

      return {
        user: {
          id: String(payload.user.id),
          username: payload.user.username,
          fullName: payload.user.full_name ?? payload.user.fullName ?? null,
          avatarUrl: payload.user.avatar_url ?? payload.user.avatarUrl ?? null,
          bio: payload.user.bio ?? null,
          location: payload.user.location ?? null,
          createdAt: payload.user.created_at ?? payload.user.createdAt ?? new Date().toISOString(),
          updatedAt: payload.user.updated_at ?? payload.user.updatedAt ?? new Date().toISOString(),
          wishlistCount: Number(
            payload.user.wishlist_count ?? payload.user.wishlistCount ?? normalizedWishlists.length,
          ),
          friendCount: Number(payload.user.friend_count ?? payload.user.friendCount ?? 0),
        },
        wishlists: normalizedWishlists,
        totals: {
          wishCount: Number(
            payload.totals?.wish_count
              ?? payload.totals?.wishCount
              ?? normalizedWishlists.reduce((sum, w) => sum + (w.wishCount || 0), 0),
          ),
          reservedCount: Number(
            payload.totals?.reserved_count
              ?? payload.totals?.reservedCount
              ?? normalizedWishlists.reduce((sum, w) => sum + (w.reservedCount || 0), 0),
          ),
        },
      };
    } catch (error) {
      console.error('Error fetching public profile:', error);
      throw error;
    }
  }
};

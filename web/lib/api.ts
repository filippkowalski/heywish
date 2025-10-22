const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'https://openai-rewrite.onrender.com/jinnie/v1';

console.log('[API Init] API_BASE_URL:', API_BASE_URL);
console.log('[API Init] process.env.NEXT_PUBLIC_API_BASE_URL:', process.env.NEXT_PUBLIC_API_BASE_URL);

// Helper function to make API calls with fetch (edge runtime compatible)
async function apiRequest<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const url = `${API_BASE_URL}${endpoint}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'X-API-Version': '1.0',
      ...options.headers,
    },
  });

  if (!response.ok) {
    throw {
      response: {
        status: response.status,
        statusText: response.statusText,
        data: await response.text(),
      },
    };
  }

  return response.json();
}

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
  reservedByUid?: string;
  reservedMessage?: string;
  reserverName?: string;
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
  slug?: string;
  coverImageUrl?: string;
  username?: string;
  fullName?: string | null;
  tags?: string[];
  wishCount: number;
  reservedCount: number;
  createdAt: string;
  updatedAt: string;
  wishes?: Wish[];
  items?: Wish[]; // Backend returns 'items' field, map to wishes
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
  isProfilePublic?: boolean;
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
  reservedByUid?: string | null;
  reserved_by_uid?: string | null;
  reserved_message?: string | null;
  reserver_name?: string | null;
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
  slug?: string | null;
  cover_image_url?: string | null;
  username?: string | null;
  full_name?: string | null;
  item_count?: number | string | null;
  wish_count?: number | string | null;
  reserved_count?: number | string | null;
  created_at: string;
  updated_at: string;
  tags?: string[] | null;
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
  is_profile_public?: boolean;
  isProfilePublic?: boolean;
};

type RawProfileTotals = {
  wish_count?: number | string | null;
  wishCount?: number | string | null;
  reserved_count?: number | string | null;
  reservedCount?: number | string | null;
};

const parseCount = (value: unknown): number => {
  if (value == null) return 0;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

const mapRawWish = (wish: RawWish): Wish => ({
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
  reservedByUid: wish.reservedByUid ?? wish.reserved_by_uid ?? undefined,
  reservedMessage: wish.reserved_message ?? undefined,
  reserverName: wish.reserver_name ?? undefined,
  purchasedBy: wish.purchasedBy ?? wish.purchased_by ?? undefined,
  purchasedAt: wish.purchasedAt ?? wish.purchased_at ?? undefined,
  createdAt: wish.createdAt ?? wish.created_at ?? new Date().toISOString(),
  updatedAt: wish.updatedAt ?? wish.updated_at ?? new Date().toISOString(),
});

// API functions
export const api = {
  // Get public wishlist by share token
  async getPublicWishlist(shareToken: string): Promise<PublicWishlistResponse> {
    try {
      const data = await apiRequest<{ wishlist: RawWishlist }>(`/public/wishlists/${shareToken}`);
      const payload = data;
      const raw = payload.wishlist;

      const tags = Array.isArray(raw.tags)
        ? (raw.tags as Array<string | null>).filter((tag): tag is string => Boolean(tag))
        : [];

      const wishes = (raw.wishes ?? raw.items ?? []).map(mapRawWish);

      const normalized: Wishlist = {
        id: String(raw.id),
        userId: String(raw.user_id),
        name: raw.name,
        description: raw.description ?? undefined,
        visibility: raw.visibility,
        shareToken: raw.share_token ?? undefined,
        slug: raw.slug ?? undefined,
        coverImageUrl: raw.cover_image_url ?? undefined,
        username: raw.username ?? undefined,
        fullName: raw.full_name ?? undefined,
        tags,
        wishCount: Number(raw.item_count ?? raw.wish_count ?? wishes.length),
        reservedCount: Number(raw.reserved_count ?? 0),
        createdAt: raw.created_at ?? new Date().toISOString(),
        updatedAt: raw.updated_at ?? new Date().toISOString(),
        wishes,
        items: wishes,
      };

      return { wishlist: normalized };
    } catch (error) {
      console.error('Error fetching public wishlist:', error);
      throw error;
    }
  },

  // Reserve a wish item
  async reserveWish(
    wishId: string,
    options?: { name?: string; email?: string; message?: string; idToken?: string }
  ): Promise<void> {
    try {
      const name = options?.name?.trim() || undefined;
      const email = options?.email?.trim();
      const note = options?.message?.trim();

      const messageParts = [];
      if (email) {
        messageParts.push(`Email: ${email}`);
      }
      if (note) {
        messageParts.push(note);
      }

      await apiRequest(`/wishes/${wishId}/reserve`, {
        method: 'POST',
        body: JSON.stringify({
          message: messageParts.join('\n') || undefined,
          hideFromOwner: false,
          reserver_name: name,
        }),
        headers: options?.idToken
          ? { Authorization: `Bearer ${options.idToken}` }
          : undefined,
      });
    } catch (error) {
      console.error('Error reserving wish:', error);
      throw error;
    }
  },

  // Cancel wish reservation
  async cancelReservation(wishId: string, idToken?: string): Promise<void> {
    try {
      await apiRequest(`/wishes/${wishId}/reserve`, {
        method: 'DELETE',
        headers: idToken
          ? { Authorization: `Bearer ${idToken}` }
          : undefined,
      });
    } catch (error) {
      console.error('Error canceling reservation:', error);
      throw error;
    }
  },

  async getPublicProfile(username: string): Promise<PublicProfileResponse> {
    try {
      console.log('[API] Fetching profile for username:', username);
      console.log('[API] Request URL:', `${API_BASE_URL}/public/users/${username}`);
      const data = await apiRequest<{
        user: RawPublicProfileUser;
        wishlists?: RawWishlist[];
        totals?: RawProfileTotals;
      }>(`/public/users/${username}`);
      console.log('[API] Profile data received for:', username);
      const payload = data;

      const rawWishlists = payload.wishlists ?? [];

      const normalizedWishlists: Wishlist[] = rawWishlists.map((wishlist) => {
        const tags = Array.isArray((wishlist as unknown as { tags?: Array<string | null> }).tags)
          ? ((wishlist as unknown as { tags?: Array<string | null> }).tags || []).filter((tag): tag is string => Boolean(tag))
          : [];

        const wishes = (wishlist.items ?? wishlist.wishes ?? []).map(mapRawWish);
        const computedWishCount = wishes.length;
        const providedWishCount = parseCount(wishlist.item_count ?? wishlist.wish_count);
        const wishCount = Math.max(providedWishCount, computedWishCount);

        const reservedFromItems = wishes.reduce((count, wish) => (wish.status === 'reserved' ? count + 1 : count), 0);
        const providedReservedCount = parseCount(wishlist.reserved_count);
        const reservedCount = Math.max(providedReservedCount, reservedFromItems);

        return {
          id: String(wishlist.id),
          userId: String(wishlist.user_id),
          name: wishlist.name,
          description: wishlist.description ?? undefined,
          visibility: wishlist.visibility,
          shareToken: wishlist.share_token ?? undefined,
          slug: wishlist.slug ?? undefined,
          coverImageUrl: wishlist.cover_image_url ?? undefined,
          username: payload.user.username,
          fullName: payload.user.full_name ?? payload.user.fullName ?? null,
          tags,
          wishCount,
          reservedCount,
          createdAt: wishlist.created_at,
          updatedAt: wishlist.updated_at,
          wishes,
          items: wishes,
        };
      });

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
          isProfilePublic: payload.user.is_profile_public ?? payload.user.isProfilePublic ?? true,
        },
        wishlists: normalizedWishlists,
        totals: {
          wishCount: Math.max(
            parseCount(payload.totals?.wish_count ?? payload.totals?.wishCount),
            normalizedWishlists.reduce((sum, w) => sum + w.wishCount, 0),
          ),
          reservedCount: Math.max(
            parseCount(payload.totals?.reserved_count ?? payload.totals?.reservedCount),
            normalizedWishlists.reduce((sum, w) => sum + w.reservedCount, 0),
          ),
        },
      };
    } catch (error: unknown) {
      console.error('[API] Error fetching public profile for:', username);
      const err = error as { message?: string; response?: { status?: number; statusText?: string; data?: unknown } };
      console.error('[API] Error details:', {
        message: err?.message,
        status: err?.response?.status,
        statusText: err?.response?.statusText,
        data: err?.response?.data,
      });
      throw error;
    }
  }
};

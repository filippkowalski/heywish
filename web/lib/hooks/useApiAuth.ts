'use client';

import { useCallback } from 'react';
import { useAuth } from '../auth/AuthContext.client';
import type { Wishlist, Wish } from '../api';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'https://openai-rewrite.onrender.com/jinnie/v1';

interface CreateWishlistData {
  name: string;
  description?: string;
  visibility: 'public' | 'friends' | 'private';
  coverImageUrl?: string;
}

interface UpdateWishlistData {
  name?: string;
  description?: string;
  visibility?: 'public' | 'friends' | 'private';
  coverImageUrl?: string;
}

interface CreateWishData {
  wishlistId?: string;
  title: string;
  description?: string;
  url?: string;
  price?: number;
  currency?: string;
  images?: string[];
}

interface UpdateWishData {
  title?: string;
  description?: string;
  url?: string;
  price?: number;
  currency?: string;
  images?: string[];
  wishlistId?: string;
}

interface UrlMetadata {
  success: boolean;
  title?: string;
  description?: string;
  image?: string;
  price?: number;
  currency?: string;
  source?: string;
}

interface UploadUrlResponse {
  uploadUrl: string;
  publicUrl: string;
}

export function useApiAuth() {
  const { user, refreshIdToken } = useAuth();

  // Helper to make authenticated requests with automatic token refresh
  const authRequest = useCallback(
    async <T>(endpoint: string, options: RequestInit = {}): Promise<T> => {
      if (!user) {
        throw new Error('User not authenticated');
      }

      // Get initial token
      let token = await user.getIdToken();

      // Make first request
      let response = await fetch(`${API_BASE_URL}${endpoint}`, {
        ...options,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
          'X-API-Version': '1.0',
          ...options.headers,
        },
      });

      // Retry once on 401 with refreshed token
      if (response.status === 401) {
        token = await refreshIdToken();
        response = await fetch(`${API_BASE_URL}${endpoint}`, {
          ...options,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
            'X-API-Version': '1.0',
            ...options.headers,
          },
        });
      }

      if (!response.ok) {
        const errorText = await response.text();
        let errorMessage = `API Error: ${response.status}`;

        try {
          const errorData = JSON.parse(errorText);
          errorMessage = errorData.error || errorData.message || errorMessage;
        } catch {
          // If not JSON, use the text
          errorMessage = errorText || errorMessage;
        }

        throw new Error(errorMessage);
      }

      // Handle 204 No Content
      if (response.status === 204) {
        return undefined as T;
      }

      return response.json();
    },
    [user, refreshIdToken]
  );

  // Get user's wishlists
  const getMyWishlists = useCallback(async (): Promise<Wishlist[]> => {
    const data = await authRequest<{ wishlists: Wishlist[] }>('/wishlists');
    return data.wishlists || [];
  }, [authRequest]);

  // Create wishlist
  const createWishlist = useCallback(
    async (data: CreateWishlistData): Promise<Wishlist> => {
      const response = await authRequest<{ wishlist: Wishlist }>('/wishlists', {
        method: 'POST',
        body: JSON.stringify(data),
      });
      return response.wishlist;
    },
    [authRequest]
  );

  // Update wishlist
  const updateWishlist = useCallback(
    async (id: string, data: UpdateWishlistData): Promise<Wishlist> => {
      const response = await authRequest<{ wishlist: Wishlist }>(`/wishlists/${id}`, {
        method: 'PATCH',
        body: JSON.stringify(data),
      });
      return response.wishlist;
    },
    [authRequest]
  );

  // Delete wishlist
  const deleteWishlist = useCallback(
    async (id: string): Promise<void> => {
      await authRequest<void>(`/wishlists/${id}`, {
        method: 'DELETE',
      });
    },
    [authRequest]
  );

  // Create wish
  const createWish = useCallback(
    async (data: CreateWishData): Promise<Wish> => {
      const response = await authRequest<{ wish: Wish }>('/wishes', {
        method: 'POST',
        body: JSON.stringify(data),
      });
      return response.wish;
    },
    [authRequest]
  );

  // Update wish
  const updateWish = useCallback(
    async (id: string, data: UpdateWishData): Promise<Wish> => {
      const response = await authRequest<{ wish: Wish }>(`/wishes/${id}`, {
        method: 'PATCH',
        body: JSON.stringify(data),
      });
      return response.wish;
    },
    [authRequest]
  );

  // Delete wish
  const deleteWish = useCallback(
    async (id: string): Promise<void> => {
      await authRequest<void>(`/wishes/${id}`, {
        method: 'DELETE',
      });
    },
    [authRequest]
  );

  // Scrape URL for metadata
  const scrapeUrl = useCallback(
    async (url: string): Promise<UrlMetadata> => {
      const response = await authRequest<{ success: boolean; metadata: Omit<UrlMetadata, 'success'> }>('/wishes/scrape-url', {
        method: 'POST',
        body: JSON.stringify({ url }),
      });
      // Backend returns { success: true, metadata: {...} }
      // Combine the outer success with the metadata fields
      return {
        success: response.success,
        ...response.metadata
      };
    },
    [authRequest]
  );

  // Get wishlist cover upload URL
  const getWishlistCoverUploadUrl = useCallback(
    async (filename: string, contentType: string): Promise<UploadUrlResponse> => {
      const response = await authRequest<UploadUrlResponse>('/upload/wishlist-cover', {
        method: 'POST',
        body: JSON.stringify({ filename, contentType }),
      });
      return response;
    },
    [authRequest]
  );

  // Get wish image upload URL
  const getWishImageUploadUrl = useCallback(
    async (filename: string, contentType: string): Promise<UploadUrlResponse> => {
      const response = await authRequest<UploadUrlResponse>('/upload/wish-image', {
        method: 'POST',
        body: JSON.stringify({ filename, contentType }),
      });
      return response;
    },
    [authRequest]
  );

  return {
    getMyWishlists,
    createWishlist,
    updateWishlist,
    deleteWishlist,
    createWish,
    updateWish,
    deleteWish,
    scrapeUrl,
    getWishlistCoverUploadUrl,
    getWishImageUploadUrl,
  };
}

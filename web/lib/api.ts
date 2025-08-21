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
  }
};
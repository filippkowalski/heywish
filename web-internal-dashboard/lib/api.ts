/**
 * API Client for Internal Admin Dashboard
 * Routes requests through server-side proxy to securely handle ADMIN_API_KEY
 */

class APIError extends Error {
  constructor(public status: number, message: string, public code?: string) {
    super(message);
    this.name = 'APIError';
  }
}

async function fetchAPI(endpoint: string, options: RequestInit = {}) {
  // Route through server-side proxy instead of calling backend directly
  const proxyUrl = `/api/proxy?endpoint=${encodeURIComponent(endpoint)}`;

  const response = await fetch(proxyUrl, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });

  if (!response.ok) {
    // Try to get error details from response
    let errorBody;
    try {
      errorBody = await response.json();
    } catch {
      errorBody = { message: 'Request failed' };
    }

    // Log detailed error info for debugging
    console.error('API Error Details:', {
      endpoint,
      proxyUrl,
      status: response.status,
      statusText: response.statusText,
      errorBody,
      method: options.method || 'GET',
    });

    throw new APIError(
      response.status,
      errorBody.error?.message || errorBody.message || `Request failed with status ${response.status}`,
      errorBody.error?.code || errorBody.code || 'UNKNOWN_ERROR'
    );
  }

  return response.json();
}

// ============================================================================
// USER MANAGEMENT
// ============================================================================

export interface CreateUserData {
  username: string;
  email?: string;
  full_name?: string;
  avatar_url?: string;
  bio?: string;
  location?: string;
  birthdate?: string;
  gender?: string;
  sign_up_method?: string;
  notification_preferences?: {
    friend_activity?: boolean;
    wishlist_updates?: boolean;
    coupon_notifications?: boolean;
    birthday_notifications?: boolean;
    discount_notifications?: boolean;
  };
}

export interface User {
  id: string;
  firebase_uid: string;
  username: string;
  email?: string;
  full_name?: string;
  avatar_url?: string;
  bio?: string;
  location?: string;
  birthdate?: string;
  gender?: string;
  sign_up_method?: string;
  notification_preferences?: any;
  created_at: number;
  updated_at: number;
  is_fake?: boolean;
}

export interface UserListResponse {
  users: User[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export async function createUser(data: CreateUserData): Promise<{ user: User; wishlist: { id: string; name: string; description: string; visibility: string } }> {
  return fetchAPI('/admin/users/create', {
    method: 'POST',
    body: JSON.stringify(data),
  });
}

export async function listUsers(params?: {
  page?: number;
  limit?: number;
  fake_only?: boolean;
  sign_up_method?: string;
}): Promise<UserListResponse> {
  const queryParams = new URLSearchParams();
  if (params?.page) queryParams.set('page', params.page.toString());
  if (params?.limit) queryParams.set('limit', params.limit.toString());
  if (params?.fake_only) queryParams.set('fake_only', 'true');
  if (params?.sign_up_method) queryParams.set('sign_up_method', params.sign_up_method);

  const query = queryParams.toString();
  return fetchAPI(`/admin/users/list${query ? `?${query}` : ''}`);
}

export async function updateUser(id: string, data: Partial<CreateUserData>): Promise<{ user: User }> {
  return fetchAPI(`/admin/users/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(data),
  });
}

export async function deleteUser(id: string): Promise<{ success: boolean }> {
  return fetchAPI(`/admin/users/${id}`, {
    method: 'DELETE',
  });
}

// ============================================================================
// STATISTICS
// ============================================================================

export interface OverviewStats {
  users: {
    total_users: number;
    users_with_email: number;
    users_with_birthdate: number;
    users_with_gender: number;
    fake_users: number;
    google_users: number;
    apple_users: number;
    email_users: number;
    anonymous_users: number;
    manual_users: number;
  };
  wishlists: {
    total_wishlists: number;
    public_wishlists: number;
    friends_wishlists: number;
    private_wishlists: number;
  };
  wishes: {
    total_wishes: number;
    available_wishes: number;
    reserved_wishes: number;
    purchased_wishes: number;
    avg_price: number;
  };
  timestamp: number;
}

export interface DemographicsStats {
  gender: Array<{ gender: string; count: number }>;
  age_groups: Array<{ age_group: string; count: number }>;
  notifications: {
    friend_activity_enabled: number;
    wishlist_updates_enabled: number;
    coupon_notifications_enabled: number;
    birthday_notifications_enabled: number;
    discount_notifications_enabled: number;
    total_users: number;
  };
  timestamp: number;
}

export interface BrandStats {
  domains: Array<{ domain: string; count: number }>;
  brands: Array<{ brand: string; count: number }>;
  timestamp: number;
}

export interface GrowthStats {
  users: Array<{ period: string; count: number }>;
  wishlists: Array<{ period: string; count: number }>;
  wishes: Array<{ period: string; count: number }>;
  period: string;
  timestamp: number;
}

export async function getOverviewStats(): Promise<OverviewStats> {
  return fetchAPI('/admin/stats/overview');
}

export async function getDemographicsStats(): Promise<DemographicsStats> {
  return fetchAPI('/admin/stats/demographics');
}

export async function getBrandStats(limit: number = 20): Promise<BrandStats> {
  return fetchAPI(`/admin/stats/brands?limit=${limit}`);
}

export async function getGrowthStats(period: 'day' | 'week' | 'month' = 'month'): Promise<GrowthStats> {
  return fetchAPI(`/admin/stats/growth?period=${period}`);
}

// ============================================================================
// WISH MANAGEMENT
// ============================================================================

export interface Wish {
  id: string;
  title: string;
  description?: string;
  url?: string;
  price?: number;
  currency?: string;
  images?: string[];
  status: string;
  priority?: number;
  quantity: number;
  wishlist_id: string;
  wishlist_name?: string;
  user_id?: string;
  username?: string;
  added_at: number;
  reserved_at?: number;
}

export interface WishListResponse {
  wishes: Wish[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export interface CreateWishData {
  username: string;
  wishlist_id: string;
  title: string;
  description?: string;
  url?: string;
  price?: number;
  currency?: string;
  images?: string[];
  priority?: number;
  quantity?: number;
}

export async function browseWishes(params?: {
  page?: number;
  limit?: number;
  username?: string;
  status?: string;
}): Promise<WishListResponse> {
  const queryParams = new URLSearchParams();
  if (params?.page) queryParams.set('page', params.page.toString());
  if (params?.limit) queryParams.set('limit', params.limit.toString());
  if (params?.username) queryParams.set('username', params.username);
  if (params?.status) queryParams.set('status', params.status);

  const query = queryParams.toString();
  return fetchAPI(`/admin/wishes/browse${query ? `?${query}` : ''}`);
}

export async function createWish(data: CreateWishData): Promise<{ wish: Wish }> {
  return fetchAPI('/admin/wishes/create', {
    method: 'POST',
    body: JSON.stringify(data),
  });
}

export async function getTopWishes(by: 'reservations' | 'price' | 'recent' = 'recent', limit: number = 20): Promise<{ wishes: Wish[]; criteria: string }> {
  return fetchAPI(`/admin/wishes/top?by=${by}&limit=${limit}`);
}

export async function updateWish(wishId: string, data: Partial<CreateWishData>): Promise<{ wish: Wish }> {
  return fetchAPI(`/admin/wishes/${wishId}`, {
    method: 'PATCH',
    body: JSON.stringify(data),
  });
}

export async function deleteWish(wishId: string): Promise<{ success: boolean }> {
  return fetchAPI(`/admin/wishes/${wishId}`, {
    method: 'DELETE',
  });
}

// ============================================================================
// AUTHENTICATION
// ============================================================================

export async function verifyPassword(password: string): Promise<boolean> {
  // This will be handled client-side by comparing with env var
  return password === process.env.ADMIN_PASSWORD;
}

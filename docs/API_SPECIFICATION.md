# HeyWish API Specification

## Base URL
```
Production: https://api.heywish.com/v1
Staging: https://staging-api.heywish.com/v1
Local: http://localhost:8080/v1
```

## Authentication

### Headers
```http
Authorization: Bearer {firebase_id_token}
Content-Type: application/json
X-API-Version: 1.0
```

### Firebase Token Verification
All API requests must include a valid Firebase ID token (including anonymous users). The backend verifies the token using Firebase Admin SDK and retrieves/creates the user record in PostgreSQL. Anonymous users are automatically created on first visit and can use all features without signing up.

### Rate Limiting
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## Endpoints

### Authentication Endpoints

#### POST /auth/sync
Sync Firebase authenticated user with our database. Called after Firebase authentication.

**Request:**
```json
{
  "firebaseToken": "eyJhbGciOiJSUzI1NiIs...",
  "username": "johndoe", // optional, for initial setup
  "fullName": "John Doe" // optional, for initial setup
}
```

**Response (200):**
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "firebaseUid": "AbcDef123456",
    "email": "user@example.com",
    "username": "johndoe",
    "fullName": "John Doe",
    "avatarUrl": null,
    "createdAt": "2024-01-15T10:00:00Z"
  },
  "isNewUser": false
}
```

**Note**: User signup/login is handled entirely by Firebase Auth on the client side. This endpoint syncs the authenticated user with our PostgreSQL database.

#### GET /auth/verify
Verify Firebase token and get user data.

**Headers:**
```http
Authorization: Bearer {firebase_id_token}
```

**Response (200):**
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "firebaseUid": "AbcDef123456",
    "email": "user@example.com",
    "username": "johndoe"
  },
  "tokenValid": true
}
```

#### POST /auth/logout
Logout user (optional, mainly for session cleanup).

**Headers:**
```http
Authorization: Bearer {firebase_id_token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

**Note**: Token refresh is handled automatically by Firebase SDK on the client side.

#### POST /auth/delete
Delete user account (GDPR compliance).

**Headers:**
```http
Authorization: Bearer {firebase_id_token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Account deleted successfully"
}
```

**Note**: This deletes the user from our PostgreSQL database. Firebase account deletion should be handled separately on the client side.

### Wishlist Endpoints

#### GET /wishlists
Get user's wishlists.

**Query Parameters:**
- `page` (integer): Page number (default: 1)
- `limit` (integer): Items per page (default: 20)
- `sort` (string): Sort by field (created_at, updated_at, name)
- `order` (string): Sort order (asc, desc)

**Response (200):**
```json
{
  "wishlists": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Birthday Wishlist",
      "description": "Things I want for my birthday",
      "occasionType": "birthday",
      "visibility": "friends",
      "coverImageUrl": "https://cdn.heywish.com/covers/123.jpg",
      "eventDate": "2024-06-15",
      "itemCount": 12,
      "reservedCount": 3,
      "shareToken": "abc123xyz",
      "createdAt": "2024-01-15T10:00:00Z",
      "updatedAt": "2024-01-20T15:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "pages": 3
  }
}
```

#### POST /wishlists
Create new wishlist.

**Request:**
```json
{
  "name": "Christmas 2024",
  "description": "My Christmas wishlist",
  "occasionType": "christmas",
  "visibility": "public",
  "eventDate": "2024-12-25",
  "coverImageUrl": "https://cdn.heywish.com/covers/xmas.jpg"
}
```

**Response (201):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "name": "Christmas 2024",
  "shareToken": "xyz789abc",
  "shareUrl": "https://heywish.com/list/xyz789abc"
}
```

#### GET /wishlists/:id
Get wishlist details with items.

**Response (200):**
```json
{
  "wishlist": {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "name": "Birthday Wishlist",
    "description": "Things I want for my birthday",
    "items": [
      {
        "id": "item-001",
        "title": "Wireless Headphones",
        "description": "Sony WH-1000XM5",
        "url": "https://amazon.com/...",
        "price": 349.99,
        "currency": "USD",
        "images": [
          "https://cdn.heywish.com/items/headphones.jpg"
        ],
        "status": "available",
        "priority": 1,
        "addedAt": "2024-01-15T10:00:00Z"
      }
    ]
  }
}
```

#### PUT /wishlists/:id
Update wishlist.

**Request:**
```json
{
  "name": "Updated Birthday List",
  "visibility": "private"
}
```

#### DELETE /wishlists/:id
Delete wishlist.

**Response (204):** No content

#### POST /wishlists/:id/share
Generate/update share settings.

**Request:**
```json
{
  "expiresAt": "2024-12-31T23:59:59Z",
  "password": "optional_password"
}
```

**Response (200):**
```json
{
  "shareUrl": "https://heywish.com/list/xyz789abc",
  "shareToken": "xyz789abc",
  "qrCode": "data:image/png;base64,..."
}
```

### Wish/Item Endpoints

#### POST /wishes
Add item to wishlist.

**Request:**
```json
{
  "wishlistId": "550e8400-e29b-41d4-a716-446655440001",
  "title": "MacBook Pro 14\"",
  "url": "https://apple.com/macbook-pro",
  "price": 1999.00,
  "currency": "USD",
  "description": "Space Gray, 512GB",
  "images": ["https://..."],
  "priority": 1,
  "quantity": 1,
  "notes": "Prefer Space Gray color"
}
```

**Response (201):**
```json
{
  "id": "wish-001",
  "wishlistId": "550e8400-e29b-41d4-a716-446655440001",
  "title": "MacBook Pro 14\"",
  "status": "available"
}
```

#### POST /wishes/scrape
Scrape product from URL.

**Request:**
```json
{
  "url": "https://www.amazon.com/dp/B08N5WRWNW",
  "wishlistId": "550e8400-e29b-41d4-a716-446655440001"
}
```

**Response (200):**
```json
{
  "product": {
    "title": "Echo Echo Dot (Echo Dot (4th Gen)",
    "price": 49.99,
    "currency": "USD",
    "images": [
      "https://m.media-amazon.com/images/I/..."
    ],
    "description": "Smart speaker with Alexa...",
    "availability": "in_stock",
    "merchant": "Amazon",
    "originalPrice": 59.99,
    "discount": 17
  },
  "scrapedAt": "2024-01-15T10:00:00Z"
}
```

#### PUT /wishes/:id
Update wish item.

**Request:**
```json
{
  "priority": 2,
  "notes": "Any color is fine",
  "quantity": 2
}
```

#### DELETE /wishes/:id
Remove item from wishlist.

**Response (204):** No content

#### POST /wishes/:id/reserve
Reserve item (for gift givers).

**Request:**
```json
{
  "message": "I got this one!",
  "hideFromOwner": true
}
```

**Response (200):**
```json
{
  "reservedBy": "user-123",
  "reservedAt": "2024-01-15T10:00:00Z",
  "status": "reserved"
}
```

#### DELETE /wishes/:id/reserve
Cancel reservation.

**Response (204):** No content

#### POST /wishes/:id/purchase
Mark item as purchased.

**Request:**
```json
{
  "purchasedAt": "2024-01-15T10:00:00Z",
  "notifyOwner": false
}
```

### Social Endpoints

#### GET /friends
Get friends list.

**Response (200):**
```json
{
  "friends": [
    {
      "id": "user-456",
      "username": "janedoe",
      "fullName": "Jane Doe",
      "avatarUrl": "https://...",
      "friendsSince": "2024-01-01T00:00:00Z",
      "wishlistCount": 5
    }
  ]
}
```

#### POST /friends/request
Send friend request.

**Request:**
```json
{
  "username": "janedoe"
}
```

#### POST /friends/accept/:requestId
Accept friend request.

**Response (200):**
```json
{
  "friend": {
    "id": "user-456",
    "username": "janedoe"
  }
}
```

#### GET /feed
Get activity feed.

**Query Parameters:**
- `type` (string): Filter by type (all, friends, following)
- `limit` (integer): Items per page

**Response (200):**
```json
{
  "activities": [
    {
      "id": "activity-001",
      "type": "wish_added",
      "user": {
        "id": "user-456",
        "username": "janedoe",
        "avatarUrl": "https://..."
      },
      "data": {
        "wishTitle": "Wireless Mouse",
        "wishlistName": "Work Setup"
      },
      "timestamp": "2024-01-15T10:00:00Z"
    }
  ]
}
```

-- Price tracking endpoints removed for MVP phase
-- Prices are stored directly in the wishes table

### User Profile Endpoints

#### GET /users/profile
Get current user profile.

**Response (200):**
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "username": "johndoe",
    "fullName": "John Doe",
    "avatarUrl": "https://...",
    "bio": "Love tech and books",
    "location": "San Francisco, CA",
    "birthdate": "1990-01-15",
    "interests": ["technology", "books", "travel"],
    "stats": {
      "wishlistCount": 5,
      "wishCount": 47,
      "friendCount": 23
    },
    "subscription": {
      "tier": "premium",
      "validUntil": "2024-12-31T23:59:59Z"
    }
  }
}
```

#### PUT /users/profile
Update user profile.

**Request:**
```json
{
  "fullName": "John Smith",
  "bio": "Updated bio",
  "interests": ["technology", "gaming"]
}
```

#### POST /users/avatar
Upload avatar image.

**Request:** Multipart form data with image file

**Response (200):**
```json
{
  "avatarUrl": "https://cdn.heywish.com/avatars/user-123.jpg"
}
```

### Search Endpoints

#### GET /search
Global search across wishlists and items.

**Query Parameters:**
- `q` (string): Search query
- `type` (string): Filter by type (all, wishlists, items, users)
- `category` (string): Filter by category
- `priceMin` (number): Minimum price
- `priceMax` (number): Maximum price

**Response (200):**
```json
{
  "results": {
    "wishlists": [...],
    "items": [...],
    "users": [...]
  },
  "total": 145
}
```

-- Analytics endpoints removed for MVP phase

## Error Responses

### Error Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  }
}
```

### Error Codes
- `AUTHENTICATION_ERROR` - Invalid credentials
- `AUTHORIZATION_ERROR` - Insufficient permissions
- `VALIDATION_ERROR` - Invalid input data
- `NOT_FOUND` - Resource not found
- `RATE_LIMIT_ERROR` - Too many requests
- `SERVER_ERROR` - Internal server error
- `SCRAPING_ERROR` - Failed to scrape URL

-- WebSocket/real-time events removed for MVP phase
-- May be added in future iterations

---

*API Version: 1.0.0 | Last Updated: January 2024*
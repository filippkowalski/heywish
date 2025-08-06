# HeyWish Technical Specification

## 1. System Architecture

### 1.1 Next.js Monolith Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Next.js Application                    │
│                  (API Routes + React)                    │
├─────────────────────────────────────────────────────────┤
│  /api/auth     │  /api/wishlists  │  /api/wishes       │
│  /api/users    │  /api/social     │  /api/scrape       │
└─────────────────────────────────────────────────────────┘
                           │
                    ┌──────┴──────┐
                    ▼             ▼
         ┌──────────────┐  ┌──────────────┐
         │ Firebase Auth│  │  PostgreSQL  │
         │   (Free)     │  │  (Render)    │
         └──────────────┘  └──────────────┘
                           │
                           ▼
                ┌──────────────────────┐
                │    Redis Cache       │
                │  (Render/Upstash)    │
                └──────────────────────┘
```

### Architecture Principles
- **Modular Monolith**: All logic in Next.js API routes, organized by domain
- **Authentication**: Firebase Auth (free tier, no Identity Platform)
- **Database**: PostgreSQL hosted on Render.com
- **Caching**: Redis via Render or Upstash for sessions and frequently accessed data
- **Deployment**: Cloudflare Pages for Next.js app
- **Mobile**: Flutter apps consume the same API

### 1.2 Authentication Flow (Firebase + PostgreSQL)

#### Anonymous Users Support
```javascript
// Users can browse and create wishlists without signing up
// 1. On first visit, create anonymous Firebase user
// 2. Store wishlist data with anonymous UID
// 3. When user decides to sign up, link anonymous account

const initializeUser = async () => {
  // Check if user is already signed in
  const currentUser = firebase.auth().currentUser;
  
  if (!currentUser) {
    // Create anonymous user
    const { user } = await firebase.auth().signInAnonymously();
    await syncUserToDatabase(user, true); // isAnonymous flag
  }
};

const convertAnonymousToFull = async (email, password) => {
  const credential = firebase.auth.EmailAuthProvider.credential(email, password);
  const { user } = await firebase.auth().currentUser.linkWithCredential(credential);
  
  // Update user record from anonymous to registered
  await db.query(`
    UPDATE users 
    SET email = $1, is_anonymous = false, upgraded_at = NOW()
    WHERE firebase_uid = $2
  `, [email, user.uid]);
};
```

#### Firebase to Database Sync
```javascript
const syncUserToDatabase = async (firebaseUser, isAnonymous = false) => {
  const { uid, email, displayName, photoURL, providerData } = firebaseUser;
  const provider = providerData?.[0]?.providerId || 'anonymous';
  
  // Upsert user in PostgreSQL
  await db.query(`
    INSERT INTO users (firebase_uid, email, full_name, avatar_url, auth_provider, is_anonymous)
    VALUES ($1, $2, $3, $4, $5, $6)
    ON CONFLICT (firebase_uid) 
    DO UPDATE SET 
      email = EXCLUDED.email,
      full_name = EXCLUDED.full_name,
      avatar_url = EXCLUDED.avatar_url,
      last_login = NOW(),
      is_anonymous = EXCLUDED.is_anonymous
  `, [uid, email, displayName, photoURL, provider, isAnonymous]);
};
```

### 1.3 Database Schema (PostgreSQL on Render)

#### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(128) UNIQUE NOT NULL, -- Firebase UID
    email VARCHAR(255) UNIQUE, -- Nullable for anonymous users
    username VARCHAR(100) UNIQUE,
    full_name VARCHAR(255),
    avatar_url TEXT,
    auth_provider VARCHAR(50), -- 'anonymous', 'password', 'google.com', 'apple.com'
    is_anonymous BOOLEAN DEFAULT false,
    upgraded_at TIMESTAMP, -- When anonymous user converted to registered
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP,
    deleted_at TIMESTAMP,
    subscription_tier VARCHAR(20) DEFAULT 'free',
    notification_preferences JSONB,
    profile_data JSONB
);
```

#### Wishlists Table
```sql
CREATE TABLE wishlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    occasion_type VARCHAR(50),
    visibility ENUM('public', 'private', 'friends', 'link_only') DEFAULT 'private',
    cover_image_url TEXT,
    event_date DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP,
    settings JSONB,
    share_token VARCHAR(100) UNIQUE
);
```

#### Wishes Table
```sql
CREATE TABLE wishes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wishlist_id UUID REFERENCES wishlists(id),
    user_id UUID REFERENCES users(id),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    url TEXT,
    price DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    images JSONB,
    merchant VARCHAR(255),
    product_id VARCHAR(255),
    status ENUM('available', 'reserved', 'purchased') DEFAULT 'available',
    reserved_by UUID REFERENCES users(id),
    priority INTEGER DEFAULT 5,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP,
    metadata JSONB,
    price_history JSONB
);
```

-- Price tracking removed for MVP phase
-- Prices will be stored directly in wishes table and updated periodically

### 1.3 API Endpoints

#### Authentication
- `POST /api/auth/signup` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `POST /api/auth/refresh` - Refresh token
- `POST /api/auth/social` - Social auth (Google/Apple)

#### Wishlists
- `GET /api/wishlists` - Get user's wishlists
- `POST /api/wishlists` - Create wishlist
- `GET /api/wishlists/:id` - Get wishlist details
- `PUT /api/wishlists/:id` - Update wishlist
- `DELETE /api/wishlists/:id` - Delete wishlist
- `POST /api/wishlists/:id/share` - Generate share link
- `GET /api/wishlists/shared/:token` - Access shared wishlist

#### Wishes
- `POST /api/wishes` - Add wish to wishlist
- `GET /api/wishes/:id` - Get wish details
- `PUT /api/wishes/:id` - Update wish
- `DELETE /api/wishes/:id` - Delete wish
- `POST /api/wishes/:id/reserve` - Reserve wish
- `POST /api/wishes/:id/unreserve` - Unreserve wish
- `POST /api/wishes/scrape` - Scrape product from URL

#### Social
- `GET /api/friends` - Get friends list
- `POST /api/friends/request` - Send friend request
- `POST /api/friends/accept/:id` - Accept friend request
- `GET /api/feed` - Get activity feed
- `GET /api/users/:username` - Get public profile

#### Price Tracking
- `GET /api/prices/:wishId/history` - Get price history
- `POST /api/prices/alert` - Set price alert
- `GET /api/prices/alerts` - Get user's price alerts
- `DELETE /api/prices/alert/:id` - Remove price alert

## 2. Web Scraping Architecture

### 2.1 Scraping Service Flow

```
URL Input → Strategy Selector → Scraper
                ↓
         [Cloudflare BR]
         [Lightweight]  → Data Extractor → ML Enhancement → Cache → Response
         [Platform API]
```

### 2.2 Cloudflare Browser Rendering Configuration

```javascript
{
  endpoint: "https://api.cloudflare.com/client/v4/accounts/{account_id}/browser-rendering",
  config: {
    wait_until: "networkidle2",
    viewport: { width: 1920, height: 1080 },
    javascript_enabled: true,
    response_format: "json",
    timeout: 10000,
    extract: {
      selectors: {
        title: ["h1", "[itemprop='name']", ".product-title"],
        price: ["[itemprop='price']", ".price", "[class*='price']"],
        images: ["[itemprop='image']", ".product-image img"],
        description: ["[itemprop='description']", ".product-description"]
      }
    }
  }
}
```

### 2.3 Data Source Priority by Merchant

| Merchant | Primary Source | Fallback | Cache TTL |
|----------|---------------|----------|-----------|
| Amazon | Product Advertising API | Browserless.io | 1 hour |
| Target | Target API | Browserless.io | 2 hours |
| Walmart | Affiliate API | Browserless.io | 2 hours |
| Best Buy | Commerce API | Browserless.io | 4 hours |
| Others | Browserless.io | Manual entry | 4 hours |

### 2.4 Price Updates (Simplified)

```javascript
// Simple cron job in Next.js API route
// Runs daily to update prices for active wishes
export async function updatePrices() {
  // Fetch wishes that need price updates
  // Scrape current prices
  // Update wishes table directly
  // No separate infrastructure needed
}
```

## 3. Mobile App Architecture (Flutter)

### 3.1 State Management (BLoC Pattern)

```dart
// Wishlist BLoC
class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final WishlistRepository repository;
  
  Stream<WishlistState> mapEventToState(WishlistEvent event) async* {
    if (event is LoadWishlists) {
      yield WishlistLoading();
      try {
        final wishlists = await repository.getWishlists();
        yield WishlistLoaded(wishlists);
      } catch (e) {
        yield WishlistError(e.toString());
      }
    }
  }
}
```

### 3.2 Deep Linking Configuration

#### iOS (Info.plist)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>heywish</string>
        </array>
    </dict>
</array>
```

#### Android (AndroidManifest.xml)
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="heywish" android:host="add"/>
</intent-filter>
```

## 4. Chrome Extension Architecture

### 4.1 Manifest V3 Configuration

```json
{
  "manifest_version": 3,
  "name": "HeyWish - Save from Anywhere",
  "version": "1.0.0",
  "permissions": [
    "activeTab",
    "storage",
    "notifications"
  ],
  "host_permissions": [
    "https://api.heywish.com/*"
  ],
  "background": {
    "service_worker": "background.js"
  },
  "content_scripts": [{
    "matches": ["<all_urls>"],
    "js": ["content.js"],
    "run_at": "document_idle"
  }],
  "action": {
    "default_popup": "popup.html",
    "default_icon": "icon.png"
  }
}
```

## 5. Infrastructure & DevOps

### 5.1 Docker Configuration

```dockerfile
# Backend Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 8080
CMD ["node", "dist/server.js"]
```

### 5.2 Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: heywish-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: heywish-api
  template:
    metadata:
      labels:
        app: heywish-api
    spec:
      containers:
      - name: api
        image: heywish/api:latest
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: heywish-secrets
              key: database-url
```

### 5.3 CI/CD Pipeline (GitHub Actions)

```yaml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
      - run: npm ci
      - run: npm test
  
  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Cloud Run
        uses: google-github-actions/deploy-cloudrun@v0
        with:
          service: heywish-api
          image: gcr.io/${{ secrets.GCP_PROJECT }}/heywish-api
```

## 6. Security Implementation

### 6.1 Authentication Flow (Firebase)
1. On first visit, create anonymous Firebase user automatically
2. Anonymous users can create wishlists and add items without signup
3. When ready to sign up, link anonymous account to email/Google/Apple
4. Firebase returns ID token (JWT) valid for 1 hour
5. Client includes Firebase ID token in all API requests
6. Backend verifies token with Firebase Admin SDK
7. Sync user data to PostgreSQL (anonymous or registered)
8. Auto-refresh handled by Firebase SDK

### 6.2 Rate Limiting
- Authentication: 5 requests per minute
- API endpoints: 100 requests per minute
- Scraping: 10 requests per minute per user
- Price checks: 1000 per day per user

### 6.3 Data Security
- Passwords: Handled by Firebase Auth (no passwords stored in our DB)
- Firebase ID tokens: Verified on each API request
- Sensitive data: AES-256 encryption for PII
- API communication: TLS 1.3
- Database: Render PostgreSQL with encryption at rest
- Connection: SSL required for database connections

## 7. Monitoring & Analytics

### 7.1 Logging Stack
- Application logs: Winston/Morgan
- Infrastructure: CloudWatch/Stackdriver
- Error tracking: Sentry
- APM: New Relic/DataDog

### 7.2 Key Metrics to Track
- API response times (p50, p95, p99)
- Scraping success rate by domain
- User engagement (DAU/MAU ratio)
- Conversion funnel metrics
- Infrastructure costs per user

## 8. Testing Strategy

### 8.1 Testing Pyramid
- Unit tests: 70% coverage minimum
- Integration tests: API endpoints
- E2E tests: Critical user journeys
- Performance tests: Load testing with K6
- Security tests: OWASP Top 10

### 8.2 Test Environments
1. Local: Docker Compose setup
2. Dev: Automatic deployment on PR
3. Staging: Production mirror
4. Production: Blue-green deployment

## 9. Performance Targets

- Page Load: < 2 seconds (FCP)
- API Response: < 200ms (p95)
- Scraping: < 3 seconds per URL
- Mobile App Launch: < 1 second
- Database Queries: < 50ms (p95)

## 10. Scalability Considerations

- Horizontal scaling for all services
- Database read replicas
- Redis cluster for caching
- CDN for static assets
- Message queue for async tasks
- Auto-scaling based on CPU/memory
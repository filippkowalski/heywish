# HeyWish Technical Specification

## 1. System Architecture

### 1.1 Microservices Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      API Gateway                         │
│                   (Express + Auth)                       │
└─────────────┬───────────────────────────────────────────┘
              │
    ┌─────────┼─────────┬──────────┬──────────┬──────────┐
    ▼         ▼         ▼          ▼          ▼          ▼
┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐
│  User  ││Wishlist││Product ││ Social ││Notif.  ││Analytics│
│Service ││Service ││Service ││Service ││Service ││Service │
└────────┘└────────┘└────────┘└────────┘└────────┘└────────┘
    │         │         │          │          │          │
    └─────────┴─────────┴──────────┴──────────┴──────────┘
                           │
                    ┌──────┴──────┐
                    │  PostgreSQL  │
                    │    Redis     │
                    │Elasticsearch │
                    └──────────────┘
```

### 1.2 Database Schema (PostgreSQL)

#### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE,
    full_name VARCHAR(255),
    avatar_url TEXT,
    auth_provider ENUM('email', 'google', 'apple'),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP,
    subscription_tier ENUM('free', 'premium') DEFAULT 'free',
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

#### Price Tracking Table
```sql
CREATE TABLE price_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wish_id UUID REFERENCES wishes(id),
    price DECIMAL(10, 2),
    currency VARCHAR(3),
    is_on_sale BOOLEAN DEFAULT FALSE,
    sale_percentage INTEGER,
    tracked_at TIMESTAMP DEFAULT NOW(),
    source VARCHAR(50),
    metadata JSONB
);
```

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

### 2.4 Price Tracking Service (Separate Worker)

```javascript
// Runs as separate Vercel Function or AWS Lambda
interface PriceTrackingConfig {
  database: 'Separate PostgreSQL or TimescaleDB',
  schedule: 'Every 4 hours for active items',
  queue: 'BullMQ or AWS SQS',
  notifications: 'Email/Push when price drops >10%'
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

### 6.1 Authentication Flow (JWT)
1. User logs in with credentials
2. Server validates and generates JWT + Refresh token
3. JWT expires in 15 minutes, Refresh token in 30 days
4. Client stores tokens securely (Keychain/Keystore)
5. Auto-refresh on 401 responses

### 6.2 Rate Limiting
- Authentication: 5 requests per minute
- API endpoints: 100 requests per minute
- Scraping: 10 requests per minute per user
- Price checks: 1000 per day per user

### 6.3 Data Encryption
- Passwords: bcrypt with salt rounds = 12
- Sensitive data: AES-256 encryption
- API communication: TLS 1.3
- Database: Encryption at rest

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
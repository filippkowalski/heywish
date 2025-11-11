# Jinnie Internal Dashboard

Internal admin dashboard for managing the Jinnie wishlist application. This dashboard provides tools for user management, statistics, brand analytics, and content moderation.

## 🚀 Features

### Dashboard Overview
- **Real-time Statistics**: Total users, wishlists, and wishes
- **Auth Provider Breakdown**: Google, Apple, Email, and Anonymous users
- **Profile Completion Metrics**: Users with email, birthdate, gender
- **Content Stats**: Wishlist visibility, wish status distribution, average prices

### User Management
- **Create Fake Users**: Manually create test users without Firebase authentication
- **Browse Users**: Paginated user list with filters (fake users, sign-up method)
- **Edit Users**: Update any user field including birthdate, gender, notification preferences
- **Delete Fake Users**: Safety check prevents deletion of real users

### Wish Management
- **Browse Wishes**: Filter by username, status, price range
- **Insert Wishes**: Add wishes directly to any user's wishlist
- **Top Wishes**: View most reserved, highest priced, or most recent wishes

### Brand Analytics
- **Domain Statistics**: Top domains from wish URLs (amazon.com, etsy.com, etc.)
- **Brand Extraction**: Common brand names extracted from wish titles
- **Visual Charts**: Bar charts and analytics

### Detailed Statistics
- **Age Demographics**: Histogram of user age groups
- **Gender Breakdown**: Pie chart of gender distribution
- **Notification Preferences**: Opt-in rates for different notification types
- **Growth Charts**: User/wishlist/wish creation over time

## 🏗️ Architecture

### Frontend
- **Framework**: Next.js 14 with App Router
- **Styling**: Tailwind CSS + Shadcn/ui components
- **Data Fetching**: SWR for client-side caching
- **Charts**: Recharts
- **Runtime**: Edge-compatible for Cloudflare Pages

### Backend
- **API**: Express.js routers in `backend_openai_proxy`
- **Database**: PostgreSQL (existing schema, zero changes)
- **Auth**: API key-based authentication (`X-Admin-Key` header)

### Security
1. **Password Protection**: Simple password gate on login page
2. **API Key**: Admin endpoints require API key in headers
3. **IP Filtering**: Cloudflare Firewall Rules (recommended)
4. **Separate Domain**: Not accessible from main jinnie.co
5. **Session Management**: 24-hour sessions with localStorage

## 📦 Installation

### Prerequisites
- Node.js 18+
- Access to backend API at `https://openai-rewrite.onrender.com`
- Admin API key configured in backend

### Setup

1. **Navigate to project directory**
```bash
cd /Users/filip.zapper/Workspace/jinnie/web-internal-dashboard
```

2. **Install dependencies**
```bash
npm install
```

3. **Configure environment variables**

Copy `.env.local.example` to `.env.local` and update:

```bash
# Admin Dashboard Configuration

# Password for accessing the dashboard (exposed to client)
NEXT_PUBLIC_ADMIN_PASSWORD=your_secure_password_here

# Backend API base URL
NEXT_PUBLIC_API_BASE_URL=https://openai-rewrite.onrender.com/jinnie/v1

# Admin API key (must match backend ADMIN_API_KEY) - server-side only
ADMIN_API_KEY=your_admin_api_key_here
```

**Important**: The `ADMIN_API_KEY` must match the key configured in the backend environment variables.

4. **Start development server**
```bash
npm run dev
```

The dashboard will be available at `http://localhost:3001`

## 🚀 Deployment

### Cloudflare Pages Setup

1. **Build for Cloudflare Pages**
```bash
npm run pages:build
```

This uses `@cloudflare/next-on-pages` to create an edge-compatible build.

2. **Deploy to Cloudflare Pages**
   - Create a new Cloudflare Pages project
   - Connect to your Git repository or use direct upload
   - Build command: `npm run pages:build`
   - Build output directory: `.vercel/output/static`
   - Set environment variables in Cloudflare Pages dashboard

3. **Configure Environment Variables**

In Cloudflare Pages project settings, add:
- `NEXT_PUBLIC_ADMIN_PASSWORD`
- `NEXT_PUBLIC_API_BASE_URL`
- `ADMIN_API_KEY`

### Cloudflare IP Filtering (Recommended)

For additional security, restrict access to your IP addresses:

1. Go to Cloudflare Dashboard → Security → WAF
2. Create a custom rule:
   - **Rule name**: "Restrict Internal Dashboard"
   - **Field**: IP Address
   - **Operator**: does not equal
   - **Value**: `your.ip.address.1`, `your.ip.address.2`
   - **Action**: Block
3. Apply to your internal dashboard Pages project

Alternatively, use **Cloudflare Access** for more advanced authentication.

## 🔐 Backend Configuration

### Admin Router Setup

The admin router is located at:
```
/Users/filip.zapper/Workspace/backend_openai_proxy/routes/jinnie/routers/admin.js
```

### Admin Middleware

Authentication middleware at:
```
/Users/filip.zapper/Workspace/backend_openai_proxy/routes/jinnie/middleware/admin-auth.js
```

### Environment Variable

Add to backend `.env` file:
```bash
ADMIN_API_KEY=your_admin_api_key_here
```

This key must match the `ADMIN_API_KEY` in the frontend `.env.local`.

### API Endpoints

All admin endpoints are prefixed with `/admin` and require the `X-Admin-Key` header.

#### User Management
- `POST /admin/users/create` - Create fake user
- `GET /admin/users/list` - List users with pagination
- `PATCH /admin/users/:id` - Update user
- `DELETE /admin/users/:id` - Delete fake user

#### Statistics
- `GET /admin/stats/overview` - Overview statistics
- `GET /admin/stats/demographics` - Demographics breakdown
- `GET /admin/stats/brands` - Brand popularity
- `GET /admin/stats/growth` - Growth over time

#### Wish Management
- `GET /admin/wishes/browse` - Browse wishes
- `POST /admin/wishes/create` - Create wish
- `GET /admin/wishes/top` - Top wishes by criteria

## 📊 Database Schema

The dashboard uses the existing PostgreSQL schema **without any modifications**.

### Key Tables Used

**users**
- `id`, `firebase_uid`, `username`, `email`, `full_name`
- `avatar_url`, `bio`, `location`, `birthdate`, `gender`
- `sign_up_method`, `notification_preferences`
- `created_at`, `updated_at`

**wishlists**
- `id`, `user_id`, `name`, `description`
- `visibility`, `cover_image_url`
- `created_at`, `updated_at`

**wishes**
- `id`, `wishlist_id`, `title`, `description`
- `url`, `price`, `currency`, `images`
- `status`, `priority`, `quantity`
- `added_at`

### Fake User Identification

Fake users created by the admin dashboard have a special `firebase_uid` pattern:
```
admin_fake_{nanoid}
```

Example: `admin_fake_a7x9k2p4m5n8`

This allows filtering fake users in queries:
```sql
WHERE firebase_uid LIKE 'admin_fake_%'
```

## 🎨 UI Components

The dashboard uses Shadcn/ui components for a consistent design:

- **Button**: Primary actions and navigation
- **Card**: Content containers and stat cards
- **Input**: Form fields
- **Label**: Form labels
- **Dialog**: Modals (coming soon)
- **Select**: Dropdowns (coming soon)
- **Tabs**: Tabbed interfaces (coming soon)

All components are located in `/components/ui/`.

## 🔧 Development

### Project Structure

```
web-internal-dashboard/
├── app/
│   ├── dashboard/
│   │   └── page.tsx           # Dashboard overview
│   ├── users/
│   │   └── page.tsx           # User management (WIP)
│   ├── wishes/
│   │   └── page.tsx           # Wish management (WIP)
│   ├── brands/
│   │   └── page.tsx           # Brand analytics (WIP)
│   ├── stats/
│   │   └── page.tsx           # Detailed statistics (WIP)
│   ├── layout.tsx             # Root layout
│   ├── page.tsx               # Login page
│   └── globals.css            # Global styles
├── components/
│   ├── ui/                    # Shadcn/ui components
│   └── dashboard-layout.tsx   # Dashboard layout with nav
├── lib/
│   ├── api.ts                 # API client
│   └── utils.ts               # Utility functions
├── .env.local                 # Environment variables (local)
├── .env.local.example         # Environment template
├── next.config.ts             # Next.js configuration
├── tailwind.config.ts         # Tailwind configuration
├── tsconfig.json              # TypeScript configuration
└── package.json               # Dependencies
```

### Adding New Features

1. **New API Endpoint**
   - Add route handler in `backend_openai_proxy/routes/jinnie/routers/admin.js`
   - Add API function in `lib/api.ts`
   - Use in component with SWR

2. **New UI Component**
   - Create component in `components/ui/`
   - Follow Shadcn/ui patterns
   - Export from component file

3. **New Page**
   - Create page in `app/{page-name}/page.tsx`
   - Wrap with `DashboardLayout`
   - Add navigation item to `dashboard-layout.tsx`

## 🧪 Testing

### Local Testing

1. Start backend server:
```bash
cd /Users/filip.zapper/Workspace/backend_openai_proxy
npm run dev
```

2. Start frontend development server:
```bash
cd /Users/filip.zapper/Workspace/jinnie/web-internal-dashboard
npm run dev
```

3. Navigate to `http://localhost:3001`
4. Log in with configured password
5. Test all features

### API Testing

Test admin endpoints directly:

```bash
# Get overview stats
curl -H "X-Admin-Key: your_key_here" \
  https://openai-rewrite.onrender.com/jinnie/v1/admin/stats/overview

# List users
curl -H "X-Admin-Key: your_key_here" \
  https://openai-rewrite.onrender.com/jinnie/v1/admin/users/list?page=1&limit=10

# Create fake user
curl -X POST \
  -H "X-Admin-Key: your_key_here" \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","full_name":"Test User"}' \
  https://openai-rewrite.onrender.com/jinnie/v1/admin/users/create
```

## 📝 TODO / Roadmap

### Phase 1: Core Features ✅
- [x] Backend admin auth middleware
- [x] Backend admin router with all endpoints
- [x] Frontend Next.js setup
- [x] Cloudflare Pages configuration
- [x] Login page with password protection
- [x] Dashboard overview page
- [x] Basic UI components

### Phase 2: User Management 🚧
- [ ] User list table with pagination
- [ ] Create fake user form
- [ ] Edit user modal
- [ ] Delete user confirmation
- [ ] User filters and search

### Phase 3: Wish Management 🚧
- [ ] Wish browse table with filters
- [ ] Create wish form
- [ ] Top wishes display
- [ ] Wish detail view

### Phase 4: Analytics & Charts 🚧
- [ ] Brand analytics with charts
- [ ] Demographics charts (age, gender)
- [ ] Notification preferences breakdown
- [ ] Growth charts (line charts)
- [ ] Integrate Recharts

### Phase 5: Polish 🚧
- [ ] Error handling improvements
- [ ] Loading states
- [ ] Toast notifications
- [ ] Responsive design
- [ ] Dark mode support

## 🔒 Security Considerations

### Authentication Levels

1. **Client-side Password**: Simple password check for internal use
2. **API Key**: Backend verifies `X-Admin-Key` header
3. **IP Filtering**: Cloudflare Firewall Rules (recommended)
4. **Separate Domain**: Not accessible from main app

### Best Practices

- Change default password in production
- Rotate API keys regularly
- Monitor access logs
- Use HTTPS only
- Set up Cloudflare Access for team collaboration

### Limitations

- Password is stored client-side (suitable for internal tool with IP filtering)
- No user roles or permissions
- No audit logging (consider adding)
- Sessions expire after 24 hours

## 🐛 Troubleshooting

### "Failed to load statistics"

**Cause**: API connection issue or incorrect API key

**Solution**:
1. Check `ADMIN_API_KEY` matches backend configuration
2. Verify backend is running and accessible
3. Check browser console for detailed error
4. Test API endpoint directly with curl

### "Invalid password"

**Cause**: Password mismatch

**Solution**:
1. Check `.env.local` has correct `NEXT_PUBLIC_ADMIN_PASSWORD`
2. Restart development server after changing env vars
3. Clear browser cache and localStorage

### Build Fails on Cloudflare Pages

**Cause**: Edge runtime compatibility issue

**Solution**:
1. Ensure using `npm run pages:build`
2. Check all dependencies are edge-compatible
3. Verify no Node.js-specific APIs in client code
4. Review build logs for specific errors

### 401 Unauthorized on API calls

**Cause**: Missing or incorrect API key

**Solution**:
1. Verify `ADMIN_API_KEY` is set in environment
2. Check API client is sending `X-Admin-Key` header
3. Inspect network requests in browser DevTools
4. Confirm backend middleware is loaded

## 📞 Support

For issues or questions:
1. Check this README
2. Review backend logs
3. Check Cloudflare Pages deployment logs
4. Inspect browser console for errors

## 📄 License

Internal tool for Jinnie. Not for public distribution.

---

**Last Updated**: 2025-11-11
**Version**: 0.1.0
**Status**: MVP Complete, Advanced Features In Progress

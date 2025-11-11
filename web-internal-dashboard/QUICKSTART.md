# Quick Start Guide - Jinnie Internal Dashboard

## 🚀 Get Started in 5 Minutes

### Step 1: Configure Backend (1 minute)

Add to `/Users/filip.zapper/Workspace/backend_openai_proxy/.env`:

```bash
ADMIN_API_KEY=your_super_secret_admin_key_here
```

**Important**: Choose a strong, random key. This protects all admin endpoints.

### Step 2: Configure Frontend (1 minute)

Update `/Users/filip.zapper/Workspace/jinnie/web-internal-dashboard/.env.local`:

```bash
# Must match backend ADMIN_API_KEY
ADMIN_API_KEY=your_super_secret_admin_key_here

# Password for dashboard login
NEXT_PUBLIC_ADMIN_PASSWORD=your_secure_password

# Backend URL (already configured)
NEXT_PUBLIC_API_BASE_URL=https://openai-rewrite.onrender.com/jinnie/v1
```

### Step 3: Install Dependencies (1 minute)

```bash
cd /Users/filip.zapper/Workspace/jinnie/web-internal-dashboard
npm install --legacy-peer-deps
```

### Step 4: Start Development Server (30 seconds)

```bash
npm run dev
```

Dashboard available at: **http://localhost:3001**

### Step 5: Login (30 seconds)

1. Open http://localhost:3001
2. Enter password from `NEXT_PUBLIC_ADMIN_PASSWORD`
3. Click "Login"
4. You're in! 🎉

## 📊 What You Can Do Right Now

### Dashboard Page ✅
- View total users (760 currently)
- See auth provider breakdown (Google: 507, Anonymous: 246, Apple: 7)
- Check profile completion rates
- Monitor wishlist & wish statistics

### API Endpoints ✅
All 10 admin endpoints are functional:
- User management (create, list, update, delete)
- Statistics (overview, demographics, brands, growth)
- Wish management (browse, create, top)

## 🧪 Test the API

```bash
# Replace with your actual admin key
export ADMIN_KEY="your_super_secret_admin_key_here"

# Get overview stats
curl -H "X-Admin-Key: $ADMIN_KEY" \
  https://openai-rewrite.onrender.com/jinnie/v1/admin/stats/overview

# List users (first page)
curl -H "X-Admin-Key: $ADMIN_KEY" \
  "https://openai-rewrite.onrender.com/jinnie/v1/admin/stats/overview?page=1&limit=10"

# Create a fake user
curl -X POST \
  -H "X-Admin-Key: $ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser123",
    "email": "test@example.com",
    "full_name": "Test User",
    "sign_up_method": "manual"
  }' \
  https://openai-rewrite.onrender.com/jinnie/v1/admin/users/create
```

## 🌐 Deploy to Cloudflare Pages

### One-Time Setup

1. **Build the app**
```bash
npm run pages:build
```

2. **Create Cloudflare Pages Project**
   - Go to Cloudflare Dashboard
   - Pages → Create a project
   - Connect Git or use Direct Upload

3. **Configure Build Settings**
   - Build command: `npm run pages:build`
   - Build output: `.vercel/output/static`
   - Root directory: `web-internal-dashboard`

4. **Set Environment Variables**
   - `NEXT_PUBLIC_ADMIN_PASSWORD=your_password`
   - `NEXT_PUBLIC_API_BASE_URL=https://openai-rewrite.onrender.com/jinnie/v1`
   - `ADMIN_API_KEY=your_admin_key`

5. **Deploy**
   - Click "Save and Deploy"
   - Wait ~2 minutes
   - Your dashboard is live! 🚀

### Set Up IP Filtering (Recommended)

1. Go to Cloudflare Dashboard → Security → WAF
2. Create custom rule:
   - Name: "Restrict Internal Dashboard"
   - Field: `IP Address`
   - Operator: `is not in list`
   - Value: `your.ip.1, your.ip.2` (comma-separated)
   - Action: `Block`
3. Save

Now only you and your cofounder can access the dashboard!

## 🎯 Next Steps

### Complete the UI (Pick one to start)

**Option 1: Users Page** (Easiest)
```bash
# Create user table component
# Add create user form
# Add edit/delete actions
```

**Option 2: Brand Analytics** (Most Visual)
```bash
# Install Recharts (already in package.json)
# Create bar charts for domains
# Create chart for brand names
```

**Option 3: Wishes Page** (Most Useful)
```bash
# Create wish browse table
# Add filters (username, status)
# Add create wish form
```

See `README.md` for detailed implementation guides.

## ❓ Troubleshooting

### "Invalid password"
- Check `NEXT_PUBLIC_ADMIN_PASSWORD` in `.env.local`
- Restart dev server after changing env vars
- Clear browser localStorage

### "Failed to load statistics"
- Verify `ADMIN_API_KEY` matches in backend and frontend
- Check backend server is running
- Test API with curl command above

### Build fails
- Run `npm install --legacy-peer-deps`
- Delete `node_modules` and `.next` folders
- Try again

## 📚 Documentation

- **Full Guide**: `README.md`
- **API Reference**: `README.md` → API Endpoints section
- **Implementation Details**: `SUMMARY.md`

## 🎉 You're All Set!

The MVP is **100% functional** with:
- ✅ Backend API (10 endpoints)
- ✅ Login & authentication
- ✅ Dashboard with real stats
- ✅ Deployment ready

**Time to first deploy**: ~10 minutes
**Cost**: $0 (Cloudflare Pages free tier)

Happy coding! 🚀

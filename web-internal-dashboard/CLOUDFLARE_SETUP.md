# Cloudflare Pages Setup Guide - Internal Dashboard

## Overview

You'll create a **second Cloudflare Pages project** (separate from your main jinnie.co site) that:
- ✅ Uses the same Git repository
- ✅ Builds only when `web-internal-dashboard/` changes
- ✅ Deploys to a different URL (e.g., `admin-jinnie.pages.dev`)
- ✅ Has separate environment variables

## Step-by-Step Setup

### 1. Create New Cloudflare Pages Project

1. Go to Cloudflare Dashboard → **Workers & Pages**
2. Click **Create Application** → **Pages** → **Connect to Git**
3. Select your repository (same as main site)
4. Click **Begin setup**

### 2. Configure Build Settings

**Project Configuration:**
```
Project name:          jinnie-internal-dashboard
Production branch:     main
Framework preset:      Next.js
```

**Build Settings:**
```
Build command:         npm run pages:build
Build output:          .vercel/output/static
Root directory:        web-internal-dashboard
```

**⚠️ IMPORTANT**: Setting `Root directory: web-internal-dashboard` ensures:
- Builds trigger ONLY when files in `web-internal-dashboard/` change
- Changes to `web/` won't trigger internal dashboard builds
- npm commands run from the `web-internal-dashboard` directory

### 3. Environment Variables

Click **Add variable** for each:

| Variable Name | Value | Note |
|--------------|-------|------|
| `NEXT_PUBLIC_ADMIN_PASSWORD` | `your_secure_password` | Simple auth password |
| `NEXT_PUBLIC_API_BASE_URL` | `https://openai-rewrite.onrender.com/jinnie/v1` | Backend API |
| `ADMIN_API_KEY` | `your_admin_key` | Must match backend key |

**🔒 Security Note**: Also set these as **Deployment Environment Variables** to keep them out of build logs.

### 4. Deploy!

Click **Save and Deploy**

- First build takes ~2-3 minutes
- You'll get a URL like: `https://jinnie-internal-dashboard.pages.dev`

### 5. Set Up Custom Domain (Optional)

If you want `admin.jinnie.co`:

1. Go to your Pages project → **Custom domains**
2. Click **Set up a custom domain**
3. Enter: `admin.jinnie.co`
4. Cloudflare auto-configures DNS
5. SSL certificate auto-provisions

## Build Triggers

### Internal Dashboard Builds When:
✅ Any file in `web-internal-dashboard/` changes
✅ `package.json` in `web-internal-dashboard/` changes
✅ You push to `main` branch with dashboard changes

### Internal Dashboard Skips Build When:
❌ Only `web/` files change
❌ Only `mobile/` files change
❌ Only `docs/` or `README.md` changes

## Comparison: Your Two Projects

| Project | URL | Root Directory | Builds When |
|---------|-----|----------------|-------------|
| **Main Site** | jinnie.co | `web` | `web/` changes |
| **Internal Dashboard** | admin-jinnie.pages.dev | `web-internal-dashboard` | `web-internal-dashboard/` changes |

Both projects:
- Use same Git repo
- Use same branch (`main`)
- Build independently
- Have separate environment variables

## IP Filtering (Extra Security)

After deployment, restrict access to your IPs:

1. Go to **Security** → **WAF**
2. Create custom rule:

```
Rule name: Restrict Internal Dashboard
If:        IP Address is not in [your.ip.1, your.ip.2]
Then:      Block
```

3. Apply to: `jinnie-internal-dashboard` project only

## Testing the Setup

### 1. Test Local Build
```bash
cd /Users/filip.zapper/Workspace/jinnie/web-internal-dashboard
npm run pages:build
```

Should succeed without errors.

### 2. Test Deployment
1. Make a small change to `web-internal-dashboard/README.md`
2. Commit and push
3. Check Cloudflare Dashboard → **Deployments**
4. Should see new build starting

### 3. Test Access
1. Open your dashboard URL
2. Enter password from `NEXT_PUBLIC_ADMIN_PASSWORD`
3. Should see dashboard with statistics

## Troubleshooting

### Build Fails: "Command not found: npm"
**Solution**: Node.js version issue. Add to env vars:
```
NODE_VERSION=18
```

### Build Fails: "Cannot find module '@cloudflare/next-on-pages'"
**Solution**: Ensure `package.json` has the dependency:
```json
"@cloudflare/next-on-pages": "^1.13.16"
```

### Environment Variables Not Working
**Solution**:
1. Check they're set in Cloudflare Pages dashboard
2. Rebuild/redeploy (env changes require rebuild)
3. Variables starting with `NEXT_PUBLIC_` are exposed to client

### API Calls Return 401
**Solution**:
1. Verify `ADMIN_API_KEY` matches backend `.env`
2. Check backend has the key set
3. Restart backend after adding key

### Builds Triggering on Wrong Changes
**Solution**:
1. Verify **Root directory** is set to `web-internal-dashboard`
2. Clear Cloudflare Pages cache
3. Force redeploy

## Maintenance

### Update Environment Variables
1. Go to Pages project → **Settings** → **Environment variables**
2. Edit/add variables
3. **Redeploy required** for changes to take effect

### View Build Logs
1. Go to **Deployments** tab
2. Click on any deployment
3. View **Build logs** to debug issues

### Rollback to Previous Version
1. Go to **Deployments** tab
2. Find working deployment
3. Click **...** → **Rollback to this deployment**

## Next Steps

Once deployed:
1. ✅ Test login and dashboard
2. ✅ Set up IP filtering
3. ✅ Configure custom domain (optional)
4. ✅ Share URL with cofounder
5. ✅ Update backend `.env` with `ADMIN_API_KEY`

---

**Deployment Time**: ~10 minutes for first setup
**Build Time**: ~2-3 minutes per deployment
**Cost**: Free on Cloudflare Pages free tier

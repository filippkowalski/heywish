# HeyWish - Next-Generation Wishlist Platform

## 🎯 Executive Summary

HeyWish is a multi-platform wishlist application designed to compete with GoWish by offering a modern, fast, and social-first experience targeting younger demographics. The platform enables users to save, organize, and share items they want from any online store, with a focus on social discovery and viral sharing through platforms like TikTok.

### Key Differentiators
- **Social Feed** - Instagram-style discovery of friend wishlists
- **TikTok-Ready** - Optimized for viral sharing with younger audiences
- **Lightning Fast** - Modern tech stack with sub-second load times
- **Smart Price Tracking** - Real-time alerts when prices drop
- **AI Gift Concierge** - Personalized gift suggestions based on social activity

## 📊 Business Model

### Revenue Streams
1. **Affiliate Commissions** (Primary - 80% of revenue)
   - Amazon (3-5%), Target (2-3%), Walmart (2-4%)
   - Focus on high-volume, free-to-use model
   
2. **Premium Subscriptions** ($4.99/month - 20% of revenue)
   - Custom themes and vanity URLs
   - Advanced analytics and insights
   - Priority support
   - Exclusive wishlist templates
   - No core features gated - purely cosmetic/convenience
   
3. **Future Monetization** (Post-MVP)
   - Merchant partnerships
   - Sponsored gift guides
   - Virtual gift cards marketplace

### Target Metrics (Year 1 - Revised)
- 25,000 registered users
- 100,000 wishes created
- $5M GMV tracked
- $30K MRR by month 12
- 15% MAU/registered ratio
- 10% premium conversion rate

## 🏗️ Technical Architecture

### Tech Stack
- **Backend**: Next.js 14 (App Router) - Modular monolith
- **Authentication**: Firebase Auth (free tier)
- **Database**: PostgreSQL on Render.com
- **Mobile**: Flutter (iOS & Android)
- **Web**: Next.js + Tailwind CSS
- **Browser Extension**: Chrome Manifest V3
- **Infrastructure**: Cloudflare Pages
- **CDN/Storage**: Cloudflare + R2
- **Scraping**: Official APIs first (Amazon, Target), Cloudflare browser rendering https://developers.cloudflare.com/browser-rendering/rest-api/json-endpoint/ fallback

### Architecture Approach
- **Modular Monolith**: Next.js API routes organized by domain
- **Simple Caching**: Redis for sessions and frequently accessed data
- **Edge Caching**: Cloudflare for static assets and API responses

## 🚀 Product Roadmap

### Phase 1: Foundation (Months 1-2)
- ✅ Supabase setup (Auth + Database)
- ✅ Next.js app with core wishlist CRUD
- ✅ Mobile apps (Flutter for iOS/Android)
- ✅ Chrome extension with one-click save
- ✅ Basic sharing and reservation system
- ✅ Responsive web application

### Phase 2: Social & Virality (Month 3)
- Social feed implementation
- Following/followers system
- TikTok-optimized sharing cards
- Deep integration with iOS/Android share sheets
- Activity notifications
- Public profile pages

### Phase 3: Monetization (Month 4)
- Amazon & Target (and all the others that are worth adding) affiliate integration
- Premium themes and vanity URLs launch
- Email and app notifications for major price drops (let's sure we ask for notification permission during onboarding)

### Phase 4: Growth & SEO (Month 5)
- SEO-optimized public wishlists
- Chatbot where a user can ask about gift ideas
- Blog with auto-generated content
- Advanced social features

## 📱 Platform-Specific Features

### Mobile (Flutter)
- Native share sheet integration
- Push notifications
- Offline wishlist access

### Web (React)
- Responsive design
- PWA capabilities
- Drag-and-drop organization
- Bulk editing tools
- Advanced filtering

### Chrome Extension
- One-click save from any site
- Price tracking overlay
- Auto-detection of products
- Quick wishlist access

## 🎨 Design Guidelines

### Brand Values
- Simple & Intuitive
- Delightful & Fun
- Trustworthy & Secure
- Fast & Responsive

### Visual Identity
- **Primary Colors**: Soft pastels with bold accents
- **Typography**: Inter/Poppins
- **Imagery**: Hand-drawn illustrations + product photos
- **Animations**: Subtle micro-interactions

## 📈 Success Metrics

### Primary KPIs
- Monthly Active Users (MAU)
- Wishes per user
- Share-to-purchase conversion
- User retention (30/60/90 day)
- Net Promoter Score (NPS)

### Technical KPIs
- Page load time < 2s
- Scraping success rate > 95%
- API response time < 200ms
- Uptime > 99.9%


---

*Building the future of gifting, one wish at a time* 🎁
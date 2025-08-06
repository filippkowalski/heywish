# HeyWish Product Requirements Document (PRD)

## 1. Product Overview

### Vision
Create the world's most intuitive and intelligent wishlist platform that transforms how people discover, save, share, and purchase gifts.

### Mission
Eliminate unwanted gifts, reduce shopping stress, and make every gift meaningful through smart technology and social connectivity.

### Success Metrics
- 100K registered users in Year 1
- 70% MAU/registered user ratio
- 40% of users creating 3+ wishlists
- 25% share-to-purchase conversion rate
- NPS score > 50

## 2. User Personas

### Primary Personas

#### Sarah - The Organized Mom (35)
- **Needs**: Track family gift ideas year-round
- **Pain Points**: Forgetting gift ideas, duplicate gifts at parties
- **Goals**: Never miss a gift opportunity, stay within budget
- **Tech Level**: Moderate

#### Mike - The Last-Minute Shopper (28)
- **Needs**: Quick gift ideas and availability
- **Pain Points**: No idea what to buy, analysis paralysis
- **Goals**: Find perfect gifts quickly
- **Tech Level**: High

#### Emma - The Social Influencer (22)
- **Needs**: Share style preferences, inspire followers
- **Pain Points**: Constantly asked "where did you get that?"
- **Goals**: Curate aesthetic wishlists, earn from recommendations
- **Tech Level**: Very High

### Secondary Personas
- **Groups/Families**: Coordinating group gifts
- **Couples**: Wedding/baby registries
- **Teens**: Birthday/holiday wishlists for parents

## 3. Core Features

### 3.1 Wishlist Management

#### Create Wishlist
**User Story**: As a user, I want to create multiple wishlists so I can organize my desires by occasion or category.

**Acceptance Criteria**:
- Can create unlimited wishlists
- Can set name, description, cover image
- Can choose privacy settings (public/private/friends)
- Can set occasion type and date
- Can duplicate existing wishlists

#### Add Items
**User Story**: As a user, I want to easily add items from any website so I can save things I find while browsing.

**Acceptance Criteria**:
- One-click add via browser extension
- Auto-fetch product details from URL
- Manual entry option with image upload
- Bulk import from other platforms
- Add notes/size/color preferences

#### Organize Items
**User Story**: As a user, I want to organize items within my wishlists so I can prioritize and categorize.

**Acceptance Criteria**:
- Drag-and-drop reordering
- Mark items as "most wanted"
- Add tags/categories
- Set quantity needed
- Archive purchased items

### 3.2 Social Features

#### Share Wishlists
**User Story**: As a user, I want to share my wishlists with friends and family so they know what I want.

**Acceptance Criteria**:
- Generate shareable link
- QR code for in-person sharing
- Social media integration
- Email invitations
- Set expiration dates for shares

#### Friend System
**User Story**: As a user, I want to connect with friends so I can see their wishlists and coordinate gifts.

**Acceptance Criteria**:
- Find friends via email/username
- Send/accept friend requests
- Create friend groups/circles
- Privacy controls per friend
- Block/unblock functionality

#### Gift Reservation
**User Story**: As a gift giver, I want to secretly reserve items so others don't buy the same gift.

**Acceptance Criteria**:
- Reserve items anonymously
- See what's already reserved
- Set reservation expiration
- Receive reminders before events
- Mark as purchased

### 3.3 Price Intelligence

#### Price Tracking
**User Story**: As a user, I want to track price changes so I can buy at the best time.

**Acceptance Criteria**:
- Automatic daily price checks
- Price history graphs
- Sale detection
- Price drop alerts
- Show savings amount

#### Smart Alerts
**User Story**: As a user, I want to be notified of important changes so I don't miss opportunities.

**Acceptance Criteria**:
- Customizable alert thresholds
- Multi-channel notifications (push/email/SMS)
- Sale start/end alerts
- Stock availability alerts
- Friend activity notifications

### 3.4 Discovery Features

#### Gift Suggestions
**User Story**: As a user, I want personalized gift ideas so I can discover new things.

**Acceptance Criteria**:
- AI-based recommendations
- Trending items in network
- Category-based browsing
- Price range filters
- Occasion-specific suggestions

#### Activity Feed
**User Story**: As a user, I want to see what my friends are wishing for so I can get gift ideas.

**Acceptance Criteria**:
- Real-time friend activity
- Privacy-respecting feed
- Like/comment on items
- Save items from feed
- Filter by friend/occasion

### 3.5 Premium Features

#### Advanced Analytics
**User Story**: As a premium user, I want detailed insights so I can optimize my shopping.

**Acceptance Criteria**:
- Spending analytics
- Price prediction models
- Best time to buy recommendations
- Savings reports
- Gift giving history

#### Priority Support
**User Story**: As a premium user, I want fast support so issues are resolved quickly.

**Acceptance Criteria**:
- 24-hour response time
- Live chat support
- Dedicated support email
- Priority bug fixes
- Early access to features

## 4. Platform-Specific Requirements

### Mobile App (iOS/Android)

#### Core Functionality
- Native share sheet integration
- Push notifications
- Offline mode with sync
- Biometric authentication
- Camera for barcode scanning
- Widget support

#### Platform Guidelines
- Follow iOS Human Interface Guidelines
- Follow Material Design for Android
- Native navigation patterns
- Platform-specific features (3D Touch, App Shortcuts)

### Web Application

#### Core Functionality
- Responsive design (mobile-first)
- PWA capabilities
- Drag-and-drop interface
- Keyboard shortcuts
- Bulk operations
- CSV import/export

#### Browser Support
- Chrome 90+
- Safari 14+
- Firefox 88+
- Edge 90+

### Browser Extension

#### Core Functionality
- One-click save from any website
- Price tracking overlay
- Quick access popup
- Auto-login
- Context menu integration

#### Supported Browsers
- Chrome/Chromium
- Firefox
- Safari
- Edge

## 5. User Flows

### Onboarding Flow
1. **Landing** → Sign up/Login
2. **Welcome** → Brief app introduction
3. **Personalization** → Select interests
4. **First Wishlist** → Guide creation
5. **Add First Item** → Tutorial
6. **Share** → Invite friends
7. **Complete** → Dashboard

### Add Item Flow
1. **Browse** → Find product online
2. **Share/Click** → Extension/Share sheet
3. **Preview** → Verify details
4. **Customize** → Add notes/preferences
5. **Select List** → Choose wishlist
6. **Confirm** → Item added

### Purchase Flow (Gift Giver)
1. **View Wishlist** → Browse items
2. **Reserve** → Claim item
3. **Purchase** → Redirect to merchant
4. **Confirm** → Mark as purchased
5. **Notify** → Update reservation status

## 6. Non-Functional Requirements

### Performance
- Page load < 2 seconds
- API response < 200ms (p95)
- 99.9% uptime
- Support 100K concurrent users

### Security
- OAuth 2.0 authentication
- End-to-end encryption for sensitive data
- GDPR/CCPA compliant
- Regular security audits
- PCI compliance for payments

### Scalability
- Horizontal scaling capability
- Multi-region deployment
- CDN for global performance
- Database sharding ready

### Accessibility
- WCAG 2.1 AA compliance
- Screen reader support
- Keyboard navigation
- High contrast mode
- Multi-language support

## 7. Integration Requirements

### Third-Party Services
- **Authentication**: Google, Apple, Facebook
- **Payments**: Stripe (future)
- **Analytics**: Mixpanel, Google Analytics
- **Monitoring**: Sentry, New Relic
- **Email**: SendGrid
- **SMS**: Twilio
- **Storage**: AWS S3/Cloudflare R2

### Merchant Integrations
- Amazon Product API
- Shopify Apps
- eBay API
- Google Shopping
- Affiliate networks (ShareASale, CJ)

## 8. Launch Strategy

### MVP Launch (Month 1-3)
- Core wishlist features
- Basic social sharing
- Web + mobile apps
- 5 beta testers → 500 beta users

### Growth Phase (Month 4-6)
- Price tracking
- Browser extension
- Friend system
- Marketing campaigns
- 5,000 users target

### Monetization Phase (Month 7-9)
- Premium tier
- Affiliate partnerships
- Merchant tools
- 25,000 users target

### Scale Phase (Month 10-12)
- International expansion
- Advanced features
- B2B offerings
- 100,000 users target

## 9. Success Criteria

### Key Results (Year 1)
- 100,000 registered users
- 500,000 wishlists created
- 2,000,000 items saved
- $10M GMV tracked
- 5% premium conversion
- 50+ NPS score

### Quality Metrics
- < 1% crash rate
- < 2% cart abandonment
- > 95% scraping success
- < 5% customer complaints
- > 4.5 app store rating

## 10. Risks & Mitigations

### Technical Risks
- **Web scraping blocks** → Multiple strategies, manual fallback
- **Scale issues** → Cloud architecture, load testing
- **Data loss** → Backups, disaster recovery

### Business Risks
- **Low adoption** → Strong marketing, viral features
- **Competition** → Unique features, better UX
- **Monetization** → Multiple revenue streams

### Legal Risks
- **Privacy concerns** → Clear policies, user control
- **Scraping legal issues** → Partner agreements, compliance
- **Affiliate compliance** → Proper disclosures

## 11. Appendix

### Competitor Analysis
- **GoWish**: 10M users, strong in Nordics
- **Giftster**: Family-focused, US market
- **Wishlistr**: Simple, web-only
- **Amazon Lists**: Limited to Amazon

### Market Opportunity
- $500B annual gift market
- 60% of gifts are unwanted
- 85% of people maintain wish lists
- 40% CAGR in social commerce

### Technical Stack Decision
- **Backend**: Node.js for JavaScript everywhere
- **Mobile**: Flutter for code reuse
- **Web**: React for component ecosystem
- **Database**: PostgreSQL for relationships
- **Cache**: Redis for performance

---

*This PRD is a living document and will be updated based on user feedback and market conditions.*
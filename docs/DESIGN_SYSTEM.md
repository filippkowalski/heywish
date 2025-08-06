# HeyWish Design System

## 🎨 Brand Identity

### Mission Statement
"Making gifting delightful, thoughtful, and effortless for everyone."

### Brand Personality
- **Friendly** - Approachable and warm
- **Smart** - Intelligent recommendations and insights  
- **Playful** - Fun micro-interactions and delightful moments
- **Trustworthy** - Secure, reliable, and transparent

## 🎨 Visual Identity

### Color Palette

#### Primary Colors
```css
--primary-500: #8B5CF6;     /* Purple - Main brand color */
--primary-400: #A78BFA;     /* Purple Light */
--primary-600: #7C3AED;     /* Purple Dark */
```

#### Secondary Colors
```css
--coral-500: #FB7185;       /* Coral - Accent, CTAs */
--mint-500: #6EE7B7;        /* Mint - Success states */
--sky-500: #38BDF8;         /* Sky - Information */
--amber-500: #FCD34D;       /* Amber - Warnings */
```

#### Neutral Colors
```css
--gray-50: #FAFAFA;         /* Background */
--gray-100: #F4F4F5;        /* Cards */
--gray-200: #E4E4E7;        /* Borders */
--gray-400: #A1A1AA;        /* Muted text */
--gray-600: #52525B;        /* Body text */
--gray-900: #18181B;        /* Headings */
```

### Typography

#### Font Families
```css
--font-display: 'Poppins', sans-serif;    /* Headings */
--font-body: 'Inter', sans-serif;         /* Body text */
--font-mono: 'JetBrains Mono', monospace; /* Prices, codes */
```

#### Font Sizes
```css
--text-xs: 0.75rem;     /* 12px */
--text-sm: 0.875rem;    /* 14px */
--text-base: 1rem;      /* 16px */
--text-lg: 1.125rem;    /* 18px */
--text-xl: 1.25rem;     /* 20px */
--text-2xl: 1.5rem;     /* 24px */
--text-3xl: 1.875rem;   /* 30px */
--text-4xl: 2.25rem;    /* 36px */
```

### Spacing System
```css
--space-1: 0.25rem;     /* 4px */
--space-2: 0.5rem;      /* 8px */
--space-3: 0.75rem;     /* 12px */
--space-4: 1rem;        /* 16px */
--space-5: 1.25rem;     /* 20px */
--space-6: 1.5rem;      /* 24px */
--space-8: 2rem;        /* 32px */
--space-10: 2.5rem;     /* 40px */
--space-12: 3rem;       /* 48px */
--space-16: 4rem;       /* 64px */
```

### Border Radius
```css
--radius-sm: 0.25rem;   /* 4px - Buttons, inputs */
--radius-md: 0.5rem;    /* 8px - Cards */
--radius-lg: 0.75rem;   /* 12px - Modals */
--radius-xl: 1rem;      /* 16px - Feature cards */
--radius-full: 9999px;  /* Pills, avatars */
```

## 📱 Component Library

### Buttons

#### Primary Button
```css
.btn-primary {
  background: var(--primary-500);
  color: white;
  padding: var(--space-3) var(--space-6);
  border-radius: var(--radius-sm);
  font-weight: 500;
  transition: all 0.2s;
}

.btn-primary:hover {
  background: var(--primary-600);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3);
}
```

#### Button Variants
- **Primary**: Main actions (Add to Wishlist, Save)
- **Secondary**: Alternative actions (Cancel, Back)
- **Ghost**: Tertiary actions (Learn More)
- **Danger**: Destructive actions (Delete)
- **Success**: Positive actions (Confirm Purchase)

### Cards

#### Wishlist Card
```
┌─────────────────────────────┐
│ [Cover Image]               │
│                             │
├─────────────────────────────┤
│ Birthday Wishlist           │
│ 12 items • 3 reserved       │
│                             │
│ [Avatar] [Avatar] +2 more   │
└─────────────────────────────┘
```

#### Product Card
```
┌─────────────────────────────┐
│ [Product Image]      [$89]  │
│                      [-25%] │
├─────────────────────────────┤
│ Product Name                │
│ ⭐ 4.5 • Amazon            │
│                             │
│ [♡ Save]  [🔗 Share]       │
└─────────────────────────────┘
```

### Form Elements

#### Input Fields
- Floating labels for better UX
- Clear error states with helpful messages
- Success validation indicators
- Auto-formatting for prices, dates

#### Select Dropdowns
- Search functionality for long lists
- Multi-select with chips
- Custom styling matching brand

### Navigation

#### Mobile Bottom Navigation
```
┌─────────────────────────────┐
│  🏠     🔍     ➕     ❤️     👤  │
│ Home  Search  Add   Lists  Profile │
└─────────────────────────────┘
```

#### Desktop Side Navigation
- Collapsible sidebar
- Icon + text combination
- Active state indicators
- Nested menu support

## 🎭 Interaction Design

### Micro-interactions

#### Adding to Wishlist
1. Click "Add" button
2. Button transforms to loading spinner
3. Success: Confetti animation + checkmark
4. Item slides into wishlist with bounce

#### Price Drop Alert
1. Badge appears with pulse animation
2. Price flashes green with downward arrow
3. Notification slides in from top
4. Auto-dismiss after 5 seconds

#### Friend Activity
1. Avatar appears with slide-up animation
2. Activity text fades in
3. Timestamp updates in real-time
4. Hover shows full details

### Loading States
- Skeleton screens for content
- Shimmer effect for cards
- Progress bars for uploads
- Spinning indicators for actions

### Empty States
- Friendly illustrations
- Helpful copy explaining what to do
- Clear CTA to get started
- Examples or suggestions

## 📐 Layout Grid

### Mobile (375px)
- Columns: 4
- Margin: 16px
- Gutter: 16px

### Tablet (768px)
- Columns: 8
- Margin: 32px
- Gutter: 24px

### Desktop (1440px)
- Columns: 12
- Margin: 64px
- Gutter: 32px

## 🎯 UI Patterns

### Onboarding Flow
1. **Welcome Screen** - Brand introduction
2. **Personalization** - Gather preferences
3. **Social Connect** - Find friends
4. **First Wishlist** - Interactive tutorial
5. **Success** - Celebration screen

### Share Wishlist Flow
1. Tap share button
2. Modal with options (Link, QR, Social)
3. Copy confirmation with toast
4. Analytics tracking

### Add Item Flow
1. **URL Method**: Paste → Auto-fetch → Review → Save
2. **Manual Method**: Form → Image upload → Details → Save
3. **Extension Method**: Click → Preview → Confirm → Added

## 🌗 Dark Mode

### Color Adjustments
```css
[data-theme="dark"] {
  --bg-primary: #0F0F10;
  --bg-secondary: #1A1A1B;
  --text-primary: #FAFAFA;
  --text-secondary: #A1A1AA;
  --border: #27272A;
}
```

### Considerations
- Reduce contrast for eye comfort
- Adjust shadows and elevations
- Use semantic color tokens
- Test readability thoroughly

## 📱 Responsive Breakpoints

```css
--mobile: 375px;
--tablet: 768px;
--desktop: 1024px;
--wide: 1440px;
```

## ♿ Accessibility

### Requirements
- WCAG 2.1 Level AA compliance
- Keyboard navigation support
- Screen reader optimization
- Color contrast ratios (4.5:1 minimum)
- Focus indicators
- Alt text for images
- ARIA labels

### Testing Checklist
- [ ] Tab navigation works logically
- [ ] All interactive elements are keyboard accessible
- [ ] Color contrast passes AA standards
- [ ] Screen reader announces all content
- [ ] Error messages are clear and helpful
- [ ] Forms are properly labeled
- [ ] Focus states are visible

## 🎨 Iconography

### Icon Style
- Line icons (2px stroke)
- Rounded corners
- Consistent 24x24px grid
- Filled variants for active states

### Icon Library
- Navigation: Home, Search, Add, Heart, User
- Actions: Share, Edit, Delete, Filter, Sort
- Status: Check, Warning, Error, Info
- Social: Facebook, Twitter, Instagram, WhatsApp
- Commerce: Cart, Tag, Gift, Store

## 🖼️ Imagery Guidelines

### Product Images
- 1:1 aspect ratio for grid view
- 16:9 for hero images
- White/neutral backgrounds preferred
- Minimum 800x800px resolution

### Illustrations
- Flat design style
- Limited color palette
- Geometric shapes
- Playful but professional

### User Avatars
- Circular crop
- Default gradient backgrounds
- Initials as fallback
- 40x40px standard size

## 📊 Data Visualization

### Price Charts
- Line graph for history
- Green for decreases
- Red for increases
- Dotted line for predictions

### Statistics
- Donut charts for categories
- Bar charts for comparisons
- Sparklines for trends

## 🎬 Animation Principles

### Timing
- Micro-interactions: 200-300ms
- Page transitions: 300-400ms
- Loading animations: Loop indefinitely
- Use ease-in-out for natural motion

### Performance
- Prefer CSS animations over JavaScript
- Use transform and opacity for smooth 60fps
- Implement will-change for heavy animations
- Provide reduced motion option

## 📝 Content Guidelines

### Voice & Tone
- **Friendly**: "Let's find the perfect gift!"
- **Encouraging**: "Great choice! Added to your wishlist"
- **Clear**: "This item is currently unavailable"
- **Helpful**: "Try adding a photo to make your wish stand out"

### Writing Principles
1. Keep it concise
2. Use active voice
3. Be conversational
4. Avoid jargon
5. Include clear CTAs

### Error Messages
- Be specific about what went wrong
- Suggest how to fix it
- Keep a friendly tone
- Provide contact support option

## 🚀 Implementation Notes

### CSS Architecture
- Use CSS-in-JS (Emotion/Styled Components)
- Implement design tokens
- Create reusable mixins
- Follow BEM naming convention

### Component Structure
```jsx
<Card variant="wishlist" elevated>
  <CardMedia image={coverImage} />
  <CardContent>
    <CardTitle>{title}</CardTitle>
    <CardDescription>{description}</CardDescription>
  </CardContent>
  <CardActions>
    <Button variant="primary">View</Button>
  </CardActions>
</Card>
```

### Design Tokens
```javascript
const tokens = {
  colors: {
    primary: '#8B5CF6',
    secondary: '#FB7185',
    // ...
  },
  spacing: {
    xs: '4px',
    sm: '8px',
    // ...
  },
  typography: {
    heading: {
      fontFamily: 'Poppins',
      fontWeight: 600,
      // ...
    }
  }
};
```

---

*This design system is a living document and will evolve with user feedback and testing.*
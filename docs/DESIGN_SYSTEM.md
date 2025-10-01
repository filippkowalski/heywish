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

Design
- Use light mode, white and grey colors, neutral
- Make sure not to hardcode colors, we want to use system/Flutter available options such as theme colorScheme etc.this will make it easier for us to add different theme modes in the future
- Use Shadcn design principles, make it beautiful and minimalistic, beautiful typography, main text is black and subtitles are usually a shade darker
- Remember about proper padding, spacing between elements and styling (again get inspiration from Shadcn design principles)
- Only use colors for accent and whenever absolutely necessary
- Less is better, we want the UI and UX to be minimalistic but also user friendly, we want user to create invoices effortlessly and quickly, if you have any idea on how we can improve something and make it easier to use, feel free to discuss it with me, we focus on core feature
- Never use gray borders with shadows. Instead, use a semi-transparent outline so the bottom edge blends with the shadow and gets darker, avoiding a 'muddy' appearance. This makes the design look 'crisp'.


---

*This design system is a living document and will evolve with user feedback and testing.*
import type { Metadata } from "next";
import { Inter, Poppins } from "next/font/google";
import Script from "next/script";
import "./globals.css";
import { SiteHeader } from "@/components/site-header";
import { CookieConsent } from "@/components/cookie-consent";
import { AppDownloadBannerWrapper } from "@/components/app-download-banner-wrapper";

const GA_MEASUREMENT_ID = "G-BRDJHGM96Y";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

const poppins = Poppins({
  variable: "--font-poppins",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "Jinnie · Your Modern Wishlist Platform",
    template: "%s · Jinnie",
  },
  description: "Create and share beautiful wishlists for any occasion. Discover trending gifts, reserve items for friends, and make gift-giving magical. Your modern genie for wishes.",
  keywords: [
    "wishlist",
    "gift registry",
    "gift ideas",
    "christmas gifts",
    "birthday wishlist",
    "wedding registry",
    "baby registry",
    "jinnie",
    "wish list app",
    "gift planning",
    "social wishlist",
    "gift reservation",
    "holiday shopping",
  ],
  authors: [{ name: "Jinnie" }],
  creator: "Jinnie",
  publisher: "Jinnie",
  applicationName: "Jinnie",
  metadataBase: new URL("https://jinnie.co"),
  alternates: {
    canonical: "https://jinnie.co",
  },
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "any" },
      { url: "/favicon-16x16.png", sizes: "16x16", type: "image/png" },
      { url: "/favicon-32x32.png", sizes: "32x32", type: "image/png" },
    ],
    apple: [
      { url: "/apple-touch-icon.png", sizes: "180x180", type: "image/png" },
    ],
  },
  openGraph: {
    title: "Jinnie · Your Modern Wishlist Platform",
    description: "Create beautiful wishlists, discover trending gifts, and make gift-giving effortless. Share your wishes with friends and family.",
    url: "https://jinnie.co",
    siteName: "Jinnie",
    images: [
      {
        url: "https://jinnie.co/og-image.png",
        width: 1200,
        height: 630,
        alt: "Jinnie - Your Modern Wishlist Platform",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Jinnie · Your Modern Wishlist Platform",
    description: "Create beautiful wishlists, discover trending gifts, and make gift-giving effortless.",
    images: ["https://jinnie.co/og-image.png"],
    creator: "@jinnieapp",
    site: "@jinnieapp",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  category: "lifestyle",
  classification: "Gift Planning & Wishlist Platform",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const structuredData = {
    "@context": "https://schema.org",
    "@type": "WebApplication",
    "name": "Jinnie",
    "description": "Create and share beautiful wishlists for any occasion. Discover trending gifts, reserve items for friends, and make gift-giving magical.",
    "url": "https://jinnie.co",
    "applicationCategory": "LifestyleApplication",
    "operatingSystem": "iOS, Android",
    "offers": {
      "@type": "Offer",
      "price": "0",
      "priceCurrency": "USD"
    },
    "aggregateRating": {
      "@type": "AggregateRating",
      "ratingValue": "5",
      "ratingCount": "1"
    }
  };

  return (
    <html lang="en">
      <head>
        {/* iOS Smart App Banner */}
        <meta name="apple-itunes-app" content="app-id=6754384455" />

        {/* Android App Intent - Opens app or redirects to Play Store */}
        <meta name="google-play-app" content="app-id=com.wishlists.gifts" />

        {/* Structured Data for SEO */}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
        />

        {/* Google Analytics - Consent Mode */}
        <Script
          id="google-analytics-consent"
          strategy="beforeInteractive"
          dangerouslySetInnerHTML={{
            __html: `
              window.dataLayer = window.dataLayer || [];
              function gtag(){dataLayer.push(arguments);}
              gtag('consent', 'default', {
                'analytics_storage': 'denied',
                'ad_storage': 'denied',
                'ad_user_data': 'denied',
                'ad_personalization': 'denied',
                'wait_for_update': 500
              });
            `,
          }}
        />
      </head>
      <body
        className={`${inter.variable} ${poppins.variable} font-sans antialiased bg-background text-foreground`}
      >
        {/* Google Analytics */}
        <Script
          src={`https://www.googletagmanager.com/gtag/js?id=${GA_MEASUREMENT_ID}`}
          strategy="afterInteractive"
        />
        <Script
          id="google-analytics"
          strategy="afterInteractive"
          dangerouslySetInnerHTML={{
            __html: `
              window.dataLayer = window.dataLayer || [];
              function gtag(){dataLayer.push(arguments);}
              gtag('js', new Date());
              gtag('config', '${GA_MEASUREMENT_ID}', {
                page_path: window.location.pathname,
              });
            `,
          }}
        />

        <AppDownloadBannerWrapper />
        <SiteHeader />
        {children}
        <CookieConsent />
      </body>
    </html>
  );
}

import type { Metadata } from "next";
import { Inter, Poppins } from "next/font/google";
import "./globals.css";
import { SiteHeader } from "@/components/site-header";

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
  return (
    <html lang="en">
      <body
        className={`${inter.variable} ${poppins.variable} font-sans antialiased bg-background text-foreground`}
      >
        <SiteHeader />
        {children}
      </body>
    </html>
  );
}

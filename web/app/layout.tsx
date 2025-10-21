import type { Metadata } from "next";
import { Inter, Poppins } from "next/font/google";
import "./globals.css";
import { DebugLogger } from "@/components/debug-logger";

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
    default: "Jinnie · Public wishlists made simple",
    template: "%s · Jinnie",
  },
  description: "Browse public profiles, explore wishlists, and reserve gifts without friction.",
  keywords: ["wishlist", "gift registry", "jinnie", "public profile"],
  authors: [{ name: "Jinnie Team" }],
  creator: "Jinnie",
  publisher: "Jinnie",
  metadataBase: new URL("https://jinnie.app"),
  openGraph: {
    title: "Jinnie · Public wishlists made simple",
    description: "Explore public profiles and reserve wishes in just a few clicks.",
    url: "https://jinnie.app",
    siteName: "Jinnie",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "Jinnie · Public wishlists",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Jinnie · Public wishlists made simple",
    description: "Explore public profiles and reserve wishes in just a few clicks.",
    images: ["/og-image.png"],
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
        <DebugLogger />
        {children}
      </body>
    </html>
  );
}

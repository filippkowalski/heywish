import type { Metadata } from "next";
import { Inter, Poppins } from "next/font/google";
import "./globals.css";

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
  title: "HeyWish - Making Gifting Delightful",
  description: "Create beautiful wishlists, share them with friends and family, and never miss the perfect gift again. The modern wishlist platform for thoughtful gifting.",
  keywords: ["wishlist", "gifts", "birthday", "christmas", "wedding registry", "gift ideas", "sharing"],
  authors: [{ name: "HeyWish Team" }],
  creator: "HeyWish",
  publisher: "HeyWish",
  metadataBase: new URL("https://heywish.com"),
  openGraph: {
    title: "HeyWish - Making Gifting Delightful",
    description: "Create beautiful wishlists, share them with friends and family, and never miss the perfect gift again.",
    url: "https://heywish.com",
    siteName: "HeyWish",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "HeyWish - Making Gifting Delightful",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "HeyWish - Making Gifting Delightful",
    description: "Create beautiful wishlists, share them with friends and family, and never miss the perfect gift again.",
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
        className={`${inter.variable} ${poppins.variable} font-sans antialiased`}
      >
        {children}
      </body>
    </html>
  );
}

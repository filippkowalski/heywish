import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import Providers from '@/components/Providers';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'HeyWish - Save & Share Your Wishlist',
  description: 'The next-generation wishlist platform for saving, sharing, and discovering the perfect gifts',
  keywords: 'wishlist, gifts, gift ideas, shopping, wish registry',
  authors: [{ name: 'HeyWish' }],
  openGraph: {
    title: 'HeyWish - Save & Share Your Wishlist',
    description: 'Create and share your wishlist with friends and family',
    url: 'https://heywish.com',
    siteName: 'HeyWish',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'HeyWish - Save & Share Your Wishlist',
    description: 'Create and share your wishlist with friends and family',
    images: ['/twitter-image.png'],
  },
  icons: {
    icon: '/favicon.ico',
    shortcut: '/favicon-16x16.png',
    apple: '/apple-touch-icon.png',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}

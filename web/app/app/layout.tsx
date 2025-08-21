import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'HeyWish - Create Beautiful Wishlists',
  description: 'Create and share beautiful wishlists with HeyWish. Start building your wishlist today - no signup required.',
  openGraph: {
    title: 'HeyWish - Create Beautiful Wishlists',
    description: 'Create and share beautiful wishlists with HeyWish. Start building your wishlist today.',
  },
};

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
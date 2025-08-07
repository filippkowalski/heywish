import { Metadata } from 'next';

export async function generateMetadata(
  { params }: { params: { token: string } }
): Promise<Metadata> {
  try {
    // Fetch wishlist data for meta tags
    const response = await fetch(
      `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/api/public/wishlists/${params.token}`,
      { cache: 'no-store' }
    );
    
    if (!response.ok) {
      return {
        title: 'Wishlist Not Found - HeyWish',
        description: 'This wishlist is private or does not exist.',
      };
    }
    
    const data = await response.json();
    const { wishlist } = data;
    
    return {
      title: `${wishlist.title} - ${wishlist.owner_name}'s Wishlist | HeyWish`,
      description: wishlist.description || `View and reserve items from ${wishlist.owner_name}'s wishlist. ${wishlist.items_count} items available.`,
      openGraph: {
        title: `${wishlist.title} - ${wishlist.owner_name}'s Wishlist`,
        description: wishlist.description || `Check out my wishlist on HeyWish! ${wishlist.items_count} items to choose from.`,
        type: 'website',
        url: wishlist.share_url,
        siteName: 'HeyWish',
        images: [
          {
            url: '/og-wishlist.png', // You'll need to create this image
            width: 1200,
            height: 630,
            alt: `${wishlist.owner_name}'s Wishlist`,
          },
        ],
      },
      twitter: {
        card: 'summary_large_image',
        title: `${wishlist.title} - ${wishlist.owner_name}'s Wishlist`,
        description: wishlist.description || `Check out my wishlist on HeyWish!`,
        images: ['/og-wishlist.png'],
      },
      robots: {
        index: true,
        follow: true,
      },
    };
  } catch (error) {
    console.error('Error generating metadata:', error);
    return {
      title: 'Wishlist - HeyWish',
      description: 'Share and manage your wishlists with HeyWish',
    };
  }
}

export default function PublicWishlistLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
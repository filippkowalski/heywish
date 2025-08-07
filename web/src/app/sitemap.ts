import { MetadataRoute } from 'next';
import { db } from '@/lib/db';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = process.env.NEXT_PUBLIC_APP_URL || 'https://heywish.app';
  
  // Static pages
  const staticPages: MetadataRoute.Sitemap = [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: `${baseUrl}/auth/login`,
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.8,
    },
    {
      url: `${baseUrl}/auth/signup`,
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.8,
    },
  ];
  
  // Dynamic pages - Public wishlists
  let publicWishlists: MetadataRoute.Sitemap = [];
  
  try {
    // Fetch all public wishlists
    const result = await db.query(
      `SELECT share_token, updated_at 
       FROM wishlists 
       WHERE visibility = 'public' 
       ORDER BY updated_at DESC 
       LIMIT 1000`
    );
    
    publicWishlists = result.rows.map((wishlist) => ({
      url: `${baseUrl}/w/${wishlist.share_token}`,
      lastModified: new Date(wishlist.updated_at),
      changeFrequency: 'weekly' as const,
      priority: 0.6,
    }));
  } catch (error) {
    console.error('Error generating sitemap:', error);
  }
  
  return [...staticPages, ...publicWishlists];
}
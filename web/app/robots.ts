import { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/api/', '/verify-reservation'],
      },
    ],
    sitemap: 'https://jinnie.co/sitemap.xml',
  };
}

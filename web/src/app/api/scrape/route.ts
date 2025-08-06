import { NextRequest, NextResponse } from 'next/server';
import { withAuth, AuthenticatedRequest } from '@/lib/auth/middleware';
import * as cheerio from 'cheerio';

// Simple scraping without external services for MVP
async function scrapeProduct(url: string) {
  try {
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      }
    });
    
    if (!response.ok) {
      throw new Error('Failed to fetch page');
    }

    const html = await response.text();
    const $ = cheerio.load(html);

    // Extract metadata
    const title = 
      $('meta[property="og:title"]').attr('content') ||
      $('meta[name="twitter:title"]').attr('content') ||
      $('title').text() ||
      '';

    const description = 
      $('meta[property="og:description"]').attr('content') ||
      $('meta[name="description"]').attr('content') ||
      $('meta[name="twitter:description"]').attr('content') ||
      '';

    const image = 
      $('meta[property="og:image"]').attr('content') ||
      $('meta[name="twitter:image"]').attr('content') ||
      '';

    // Try to extract price (common patterns)
    let price = null;
    const pricePatterns = [
      $('meta[property="product:price:amount"]').attr('content'),
      $('meta[property="og:price:amount"]').attr('content'),
      $('[itemprop="price"]').attr('content'),
      $('.price').first().text(),
      $('[class*="price"]').first().text(),
      $('[data-price]').attr('data-price'),
    ];

    for (const pattern of pricePatterns) {
      if (pattern) {
        const cleanPrice = pattern.replace(/[^0-9.,]/g, '');
        if (cleanPrice) {
          price = parseFloat(cleanPrice.replace(',', ''));
          break;
        }
      }
    }

    // Extract merchant from URL
    const urlObj = new URL(url);
    const merchant = urlObj.hostname.replace('www.', '').split('.')[0];

    return {
      title: title.substring(0, 500),
      description: description.substring(0, 1000),
      image,
      price,
      merchant: merchant.charAt(0).toUpperCase() + merchant.slice(1),
      url,
    };
  } catch (error) {
    console.error('Scraping error:', error);
    throw error;
  }
}

// POST /api/scrape - Scrape product from URL
export async function POST(request: NextRequest) {
  return withAuth(request, async (req: AuthenticatedRequest) => {
    try {
      const { url } = await req.json();

      if (!url) {
        return NextResponse.json(
          { error: 'URL is required' },
          { status: 400 }
        );
      }

      // Validate URL
      try {
        new URL(url);
      } catch {
        return NextResponse.json(
          { error: 'Invalid URL' },
          { status: 400 }
        );
      }

      const productData = await scrapeProduct(url);

      return NextResponse.json({
        success: true,
        product: productData,
        scrapedAt: new Date().toISOString(),
      });
    } catch (error: any) {
      console.error('Scrape API error:', error);
      return NextResponse.json(
        { 
          error: 'Failed to scrape product',
          details: error.message 
        },
        { status: 500 }
      );
    }
  });
}
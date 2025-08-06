import { NextRequest, NextResponse } from 'next/server';
import { withAuth, AuthenticatedRequest } from '@/lib/auth/middleware';
import { queryOne } from '@/lib/db';

// POST /api/wishes - Add wish to wishlist
export async function POST(request: NextRequest) {
  return withAuth(request, async (req: AuthenticatedRequest) => {
    try {
      const body = await req.json();
      const {
        wishlistId,
        title,
        description,
        url,
        price,
        currency = 'USD',
        images = [],
        merchant,
        productId,
        priority = 5,
        quantity = 1,
        notes,
      } = body;

      if (!wishlistId || !title) {
        return NextResponse.json(
          { error: 'Wishlist ID and title are required' },
          { status: 400 }
        );
      }

      // Verify wishlist ownership
      const wishlist = await queryOne(
        'SELECT * FROM wishlists WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
        [wishlistId, req.user.id]
      );

      if (!wishlist) {
        return NextResponse.json(
          { error: 'Wishlist not found' },
          { status: 404 }
        );
      }

      const wish = await queryOne(
        `INSERT INTO wishes (
          wishlist_id,
          user_id,
          title,
          description,
          url,
          price,
          currency,
          images,
          merchant,
          product_id,
          priority,
          quantity,
          notes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        RETURNING *`,
        [
          wishlistId,
          req.user.id,
          title,
          description,
          url,
          price,
          currency,
          JSON.stringify(images),
          merchant,
          productId,
          priority,
          quantity,
          notes,
        ]
      );

      return NextResponse.json(wish, { status: 201 });
    } catch (error) {
      console.error('Error creating wish:', error);
      return NextResponse.json(
        { error: 'Failed to create wish' },
        { status: 500 }
      );
    }
  });
}
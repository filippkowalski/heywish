import { NextRequest, NextResponse } from 'next/server';
import { withAuth, AuthenticatedRequest } from '@/lib/auth/middleware';
import { query, queryOne } from '@/lib/db';
import { randomBytes } from 'crypto';

// GET /api/wishlists - Get user's wishlists
export async function GET(request: NextRequest) {
  return withAuth(request, async (req: AuthenticatedRequest) => {
    try {
      const { searchParams } = new URL(req.url);
      const page = parseInt(searchParams.get('page') || '1');
      const limit = parseInt(searchParams.get('limit') || '20');
      const offset = (page - 1) * limit;

      const wishlists = await query(
        `SELECT 
          w.*,
          COUNT(DISTINCT wi.id) as item_count,
          COUNT(DISTINCT CASE WHEN wi.status = 'reserved' THEN wi.id END) as reserved_count
        FROM wishlists w
        LEFT JOIN wishes wi ON wi.wishlist_id = w.id AND wi.deleted_at IS NULL
        WHERE w.user_id = $1 AND w.deleted_at IS NULL
        GROUP BY w.id
        ORDER BY w.created_at DESC
        LIMIT $2 OFFSET $3`,
        [req.user.id, limit, offset]
      );

      const totalResult = await queryOne(
        'SELECT COUNT(*) as total FROM wishlists WHERE user_id = $1 AND deleted_at IS NULL',
        [req.user.id]
      );

      return NextResponse.json({
        wishlists,
        pagination: {
          page,
          limit,
          total: parseInt(totalResult?.total || '0'),
          pages: Math.ceil(parseInt(totalResult?.total || '0') / limit),
        },
      });
    } catch (error) {
      console.error('Error fetching wishlists:', error);
      return NextResponse.json(
        { error: 'Failed to fetch wishlists' },
        { status: 500 }
      );
    }
  });
}

// POST /api/wishlists - Create new wishlist
export async function POST(request: NextRequest) {
  return withAuth(request, async (req: AuthenticatedRequest) => {
    try {
      const body = await req.json();
      const {
        name,
        description,
        occasionType,
        visibility = 'private',
        coverImageUrl,
        eventDate,
      } = body;

      if (!name) {
        return NextResponse.json(
          { error: 'Name is required' },
          { status: 400 }
        );
      }

      // Generate unique share token
      const shareToken = randomBytes(16).toString('hex');

      const wishlist = await queryOne(
        `INSERT INTO wishlists (
          user_id,
          name,
          description,
          occasion_type,
          visibility,
          cover_image_url,
          event_date,
          share_token
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *`,
        [
          req.user.id,
          name,
          description,
          occasionType,
          visibility,
          coverImageUrl,
          eventDate,
          shareToken,
        ]
      );

      return NextResponse.json(wishlist, { status: 201 });
    } catch (error) {
      console.error('Error creating wishlist:', error);
      return NextResponse.json(
        { error: 'Failed to create wishlist' },
        { status: 500 }
      );
    }
  });
}
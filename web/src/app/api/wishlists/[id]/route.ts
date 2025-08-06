import { NextRequest, NextResponse } from 'next/server';
import { withAuth, AuthenticatedRequest } from '@/lib/auth/middleware';
import { query, queryOne } from '@/lib/db';

// GET /api/wishlists/[id] - Get wishlist details with items
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  return withAuth(request, async (req: AuthenticatedRequest) => {
    try {
      const wishlist = await queryOne(
        'SELECT * FROM wishlists WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
        [params.id, req.user.id]
      );

      if (!wishlist) {
        return NextResponse.json(
          { error: 'Wishlist not found' },
          { status: 404 }
        );
      }

      const items = await query(
        `SELECT 
          w.*,
          u.username as reserved_by_username,
          u.full_name as reserved_by_name
        FROM wishes w
        LEFT JOIN users u ON u.id = w.reserved_by
        WHERE w.wishlist_id = $1 AND w.deleted_at IS NULL
        ORDER BY w.priority ASC, w.created_at DESC`,
        [params.id]
      );

      return NextResponse.json({
        ...wishlist,
        items,
      });
    } catch (error) {
      console.error('Error fetching wishlist:', error);
      return NextResponse.json(
        { error: 'Failed to fetch wishlist' },
        { status: 500 }
      );
    }
  });
}

// PUT /api/wishlists/[id] - Update wishlist
export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  return withAuth(request, async (req: AuthenticatedRequest) => {
    try {
      const body = await req.json();
      const {
        name,
        description,
        occasionType,
        visibility,
        coverImageUrl,
        eventDate,
      } = body;

      // Check ownership
      const existing = await queryOne(
        'SELECT * FROM wishlists WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
        [params.id, req.user.id]
      );

      if (!existing) {
        return NextResponse.json(
          { error: 'Wishlist not found' },
          { status: 404 }
        );
      }

      const wishlist = await queryOne(
        `UPDATE wishlists
        SET 
          name = COALESCE($2, name),
          description = COALESCE($3, description),
          occasion_type = COALESCE($4, occasion_type),
          visibility = COALESCE($5, visibility),
          cover_image_url = COALESCE($6, cover_image_url),
          event_date = COALESCE($7, event_date)
        WHERE id = $1
        RETURNING *`,
        [
          params.id,
          name,
          description,
          occasionType,
          visibility,
          coverImageUrl,
          eventDate,
        ]
      );

      return NextResponse.json(wishlist);
    } catch (error) {
      console.error('Error updating wishlist:', error);
      return NextResponse.json(
        { error: 'Failed to update wishlist' },
        { status: 500 }
      );
    }
  });
}

// DELETE /api/wishlists/[id] - Delete wishlist (soft delete)
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  return withAuth(request, async (req: AuthenticatedRequest) => {
    try {
      // Check ownership
      const existing = await queryOne(
        'SELECT * FROM wishlists WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
        [params.id, req.user.id]
      );

      if (!existing) {
        return NextResponse.json(
          { error: 'Wishlist not found' },
          { status: 404 }
        );
      }

      await queryOne(
        'UPDATE wishlists SET deleted_at = NOW() WHERE id = $1',
        [params.id]
      );

      return NextResponse.json({ success: true }, { status: 204 });
    } catch (error) {
      console.error('Error deleting wishlist:', error);
      return NextResponse.json(
        { error: 'Failed to delete wishlist' },
        { status: 500 }
      );
    }
  });
}
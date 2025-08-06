import { NextRequest, NextResponse } from 'next/server';
import { withAuth, AuthenticatedRequest } from '@/lib/auth/middleware';
import { queryOne } from '@/lib/db';

// POST /api/wishes/[id]/reserve - Reserve a wish
export async function POST(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  return withAuth(request, async (req: AuthenticatedRequest) => {
    try {
      // Get wish details
      const wish = await queryOne(
        'SELECT * FROM wishes WHERE id = $1 AND deleted_at IS NULL',
        [params.id]
      );

      if (!wish) {
        return NextResponse.json(
          { error: 'Wish not found' },
          { status: 404 }
        );
      }

      // Can't reserve your own wish
      if (wish.user_id === req.user.id) {
        return NextResponse.json(
          { error: 'Cannot reserve your own wish' },
          { status: 400 }
        );
      }

      // Check if already reserved
      if (wish.status === 'reserved' || wish.reserved_by) {
        return NextResponse.json(
          { error: 'Wish is already reserved' },
          { status: 400 }
        );
      }

      // Reserve the wish
      const updated = await queryOne(
        `UPDATE wishes
        SET 
          status = 'reserved',
          reserved_by = $2,
          reserved_at = NOW()
        WHERE id = $1
        RETURNING *`,
        [params.id, req.user.id]
      );

      // Create activity record
      await queryOne(
        `INSERT INTO activities (user_id, type, wish_id, wishlist_id, data)
        VALUES ($1, 'wish_reserved', $2, $3, $4)`,
        [
          req.user.id,
          params.id,
          wish.wishlist_id,
          JSON.stringify({ wish_title: wish.title })
        ]
      );

      return NextResponse.json({
        success: true,
        wish: updated,
      });
    } catch (error) {
      console.error('Error reserving wish:', error);
      return NextResponse.json(
        { error: 'Failed to reserve wish' },
        { status: 500 }
      );
    }
  });
}

// DELETE /api/wishes/[id]/reserve - Cancel reservation
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  return withAuth(request, async (req: AuthenticatedRequest) => {
    try {
      // Get wish details
      const wish = await queryOne(
        'SELECT * FROM wishes WHERE id = $1 AND deleted_at IS NULL',
        [params.id]
      );

      if (!wish) {
        return NextResponse.json(
          { error: 'Wish not found' },
          { status: 404 }
        );
      }

      // Check if user has reserved this wish
      if (wish.reserved_by !== req.user.id) {
        return NextResponse.json(
          { error: 'You have not reserved this wish' },
          { status: 400 }
        );
      }

      // Cancel reservation
      const updated = await queryOne(
        `UPDATE wishes
        SET 
          status = 'available',
          reserved_by = NULL,
          reserved_at = NULL
        WHERE id = $1
        RETURNING *`,
        [params.id]
      );

      return NextResponse.json({
        success: true,
        wish: updated,
      });
    } catch (error) {
      console.error('Error canceling reservation:', error);
      return NextResponse.json(
        { error: 'Failed to cancel reservation' },
        { status: 500 }
      );
    }
  });
}
import { NextRequest, NextResponse } from 'next/server';
import { withAuth, AuthenticatedRequest } from '@/lib/auth/middleware';
import { queryOne } from '@/lib/db';

// PUT /api/wishes/[id] - Update wish
export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  return withAuth(request, async (req: AuthenticatedRequest) => {
    try {
      const body = await req.json();
      const {
        title,
        description,
        url,
        price,
        currency,
        images,
        priority,
        quantity,
        notes,
      } = body;

      // Check ownership
      const existing = await queryOne(
        'SELECT * FROM wishes WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
        [params.id, req.user.id]
      );

      if (!existing) {
        return NextResponse.json(
          { error: 'Wish not found' },
          { status: 404 }
        );
      }

      const wish = await queryOne(
        `UPDATE wishes
        SET 
          title = COALESCE($2, title),
          description = COALESCE($3, description),
          url = COALESCE($4, url),
          price = COALESCE($5, price),
          currency = COALESCE($6, currency),
          images = COALESCE($7, images),
          priority = COALESCE($8, priority),
          quantity = COALESCE($9, quantity),
          notes = COALESCE($10, notes)
        WHERE id = $1
        RETURNING *`,
        [
          params.id,
          title,
          description,
          url,
          price,
          currency,
          images ? JSON.stringify(images) : null,
          priority,
          quantity,
          notes,
        ]
      );

      return NextResponse.json(wish);
    } catch (error) {
      console.error('Error updating wish:', error);
      return NextResponse.json(
        { error: 'Failed to update wish' },
        { status: 500 }
      );
    }
  });
}

// DELETE /api/wishes/[id] - Delete wish
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  return withAuth(request, async (req: AuthenticatedRequest) => {
    try {
      // Check ownership
      const existing = await queryOne(
        'SELECT * FROM wishes WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
        [params.id, req.user.id]
      );

      if (!existing) {
        return NextResponse.json(
          { error: 'Wish not found' },
          { status: 404 }
        );
      }

      await queryOne(
        'UPDATE wishes SET deleted_at = NOW() WHERE id = $1',
        [params.id]
      );

      return NextResponse.json({ success: true }, { status: 204 });
    } catch (error) {
      console.error('Error deleting wish:', error);
      return NextResponse.json(
        { error: 'Failed to delete wish' },
        { status: 500 }
      );
    }
  });
}
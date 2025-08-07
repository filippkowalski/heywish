import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';

export async function GET(
  request: NextRequest,
  { params }: { params: { token: string } }
) {
  try {
    const { token } = params;

    if (!token) {
      return NextResponse.json(
        { error: 'Share token is required' },
        { status: 400 }
      );
    }

    // Get wishlist by share token (only public wishlists)
    const wishlist = await db.query(
      `SELECT 
        w.id,
        w.title,
        w.description,
        w.created_at,
        u.name as owner_name,
        u.id as owner_id
      FROM wishlists w
      JOIN users u ON w.user_id = u.id
      WHERE w.share_token = $1 AND w.visibility = 'public'`,
      [token]
    );

    if (wishlist.rows.length === 0) {
      return NextResponse.json(
        { error: 'Wishlist not found or is private' },
        { status: 404 }
      );
    }

    const wishlistData = wishlist.rows[0];

    // Get all wishes for this wishlist
    const wishes = await db.query(
      `SELECT 
        id,
        title,
        url,
        price,
        image_url,
        notes,
        reserved_by,
        created_at,
        CASE 
          WHEN reserved_by IS NOT NULL THEN true 
          ELSE false 
        END as is_reserved
      FROM wishes
      WHERE wishlist_id = $1
      ORDER BY created_at DESC`,
      [wishlistData.id]
    );

    // Get viewer's reservation ID from cookie/header if exists
    const viewerReserverId = request.headers.get('X-Reserver-Id') || 
                           request.cookies.get('heywish_reserver_id')?.value;
    
    // Don't expose who reserved items (privacy), but indicate if viewer reserved it
    const sanitizedWishes = wishes.rows.map(wish => ({
      id: wish.id,
      title: wish.title,
      url: wish.url,
      price: wish.price,
      image_url: wish.image_url,
      notes: wish.notes,
      created_at: wish.created_at,
      is_reserved: wish.is_reserved,
      reserved_by_viewer: viewerReserverId && wish.reserved_by === viewerReserverId
    }));

    return NextResponse.json({
      wishlist: {
        ...wishlistData,
        share_url: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/w/${token}`,
        items_count: sanitizedWishes.length,
        reserved_count: sanitizedWishes.filter(w => w.is_reserved).length
      },
      wishes: sanitizedWishes
    });
  } catch (error) {
    console.error('Error fetching public wishlist:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// Reserve an item (for public viewers)
export async function POST(
  request: NextRequest,
  { params }: { params: { token: string } }
) {
  try {
    const { token } = params;
    const body = await request.json();
    const { wishId, reserverName, reserverEmail } = body;

    if (!wishId) {
      return NextResponse.json(
        { error: 'Wish ID is required' },
        { status: 400 }
      );
    }

    // Verify the wishlist is public and get its ID
    const wishlist = await db.query(
      `SELECT id FROM wishlists 
       WHERE share_token = $1 AND visibility = 'public'`,
      [token]
    );

    if (wishlist.rows.length === 0) {
      return NextResponse.json(
        { error: 'Wishlist not found or is private' },
        { status: 404 }
      );
    }

    const wishlistId = wishlist.rows[0].id;

    // Check if the wish belongs to this wishlist and is not already reserved
    const wish = await db.query(
      `SELECT id, reserved_by 
       FROM wishes 
       WHERE id = $1 AND wishlist_id = $2`,
      [wishId, wishlistId]
    );

    if (wish.rows.length === 0) {
      return NextResponse.json(
        { error: 'Item not found' },
        { status: 404 }
      );
    }

    if (wish.rows[0].reserved_by) {
      return NextResponse.json(
        { error: 'Item is already reserved' },
        { status: 400 }
      );
    }

    // Get existing reserver ID from cookie, or create a new one
    let reserverId = request.cookies.get('heywish_reserver_id')?.value;
    
    if (!reserverId) {
      // Create a new reserver ID if one doesn't exist
      reserverId = `anon_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    // Reserve the item
    await db.query(
      `UPDATE wishes 
       SET reserved_by = $1, 
           reserver_name = $2,
           reserver_email = $3,
           reserved_at = NOW()
       WHERE id = $4`,
      [reserverId, reserverName || 'Anonymous', reserverEmail || null, wishId]
    );

    // Create response with cookie
    const response = NextResponse.json({
      success: true,
      message: 'Item reserved successfully',
      reserverId // Return this so the user can unreserve later
    });
    
    // Set a persistent cookie to track this user's reservations
    response.cookies.set('heywish_reserver_id', reserverId, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 365, // 1 year
      path: '/'
    });
    
    return response;
  } catch (error) {
    console.error('Error reserving item:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// Unreserve an item
export async function DELETE(
  request: NextRequest,
  { params }: { params: { token: string } }
) {
  try {
    const { token } = params;
    const { searchParams } = new URL(request.url);
    const wishId = searchParams.get('wishId');
    
    // Get reserver ID from cookie
    const reserverId = request.cookies.get('heywish_reserver_id')?.value;

    if (!wishId) {
      return NextResponse.json(
        { error: 'Wish ID is required' },
        { status: 400 }
      );
    }
    
    if (!reserverId) {
      return NextResponse.json(
        { error: 'You are not authorized to unreserve items' },
        { status: 403 }
      );
    }

    // Verify the wishlist is public
    const wishlist = await db.query(
      `SELECT id FROM wishlists 
       WHERE share_token = $1 AND visibility = 'public'`,
      [token]
    );

    if (wishlist.rows.length === 0) {
      return NextResponse.json(
        { error: 'Wishlist not found or is private' },
        { status: 404 }
      );
    }

    // Unreserve the item only if the reserver ID matches
    const result = await db.query(
      `UPDATE wishes 
       SET reserved_by = NULL,
           reserver_name = NULL,
           reserver_email = NULL,
           reserved_at = NULL
       WHERE id = $1 AND reserved_by = $2
       RETURNING id`,
      [wishId, reserverId]
    );

    if (result.rows.length === 0) {
      return NextResponse.json(
        { error: 'Unable to unreserve item. You may not be the reserver.' },
        { status: 403 }
      );
    }

    return NextResponse.json({
      success: true,
      message: 'Item unreserved successfully'
    });
  } catch (error) {
    console.error('Error unreserving item:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
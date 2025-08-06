import { NextRequest, NextResponse } from 'next/server';
import { verifyIdToken } from '@/lib/firebase/admin';
import { query, queryOne } from '@/lib/db';

export async function POST(request: NextRequest) {
  try {
    const { firebaseToken, username, fullName } = await request.json();

    if (!firebaseToken) {
      return NextResponse.json(
        { error: 'Firebase token is required' },
        { status: 400 }
      );
    }

    // Verify Firebase token
    const { success, decodedToken } = await verifyIdToken(firebaseToken);

    if (!success || !decodedToken) {
      return NextResponse.json(
        { error: 'Invalid Firebase token' },
        { status: 401 }
      );
    }

    const { uid, email, name, picture } = decodedToken;
    const isAnonymous = !email;

    // Check if user exists
    let user = await queryOne(
      'SELECT * FROM users WHERE firebase_uid = $1',
      [uid]
    );

    if (!user) {
      // Create new user
      user = await queryOne(
        `INSERT INTO users (
          firebase_uid, 
          email, 
          username, 
          full_name, 
          avatar_url, 
          auth_provider, 
          is_anonymous
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *`,
        [
          uid,
          email || null,
          username || null,
          fullName || name || null,
          picture || null,
          decodedToken.firebase?.sign_in_provider || 'anonymous',
          isAnonymous
        ]
      );
    } else {
      // Update existing user
      user = await queryOne(
        `UPDATE users 
        SET 
          email = COALESCE($2, email),
          username = COALESCE($3, username),
          full_name = COALESCE($4, full_name),
          avatar_url = COALESCE($5, avatar_url),
          last_login = NOW(),
          is_anonymous = $6
        WHERE firebase_uid = $1
        RETURNING *`,
        [
          uid,
          email || null,
          username || user.username,
          fullName || name || user.full_name,
          picture || user.avatar_url,
          isAnonymous
        ]
      );
    }

    return NextResponse.json({
      user: {
        id: user.id,
        firebaseUid: user.firebase_uid,
        email: user.email,
        username: user.username,
        fullName: user.full_name,
        avatarUrl: user.avatar_url,
        isAnonymous: user.is_anonymous,
        createdAt: user.created_at,
      },
      isNewUser: !user.last_login,
    });
  } catch (error) {
    console.error('Error syncing user:', error);
    return NextResponse.json(
      { error: 'Failed to sync user' },
      { status: 500 }
    );
  }
}
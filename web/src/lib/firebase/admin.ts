import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const firebaseAdminConfig = {
  projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
  clientEmail: process.env.FIREBASE_ADMIN_CLIENT_EMAIL,
  privateKey: process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, '\n'),
};

// Initialize Firebase Admin
const adminApp = getApps().length === 0 
  ? initializeApp({
      credential: cert(firebaseAdminConfig),
    })
  : getApps()[0];

const adminAuth = getAuth(adminApp);

export { adminApp, adminAuth };

/**
 * Verify Firebase ID token
 */
export async function verifyIdToken(token: string) {
  try {
    const decodedToken = await adminAuth.verifyIdToken(token);
    return { success: true, decodedToken };
  } catch (error) {
    console.error('Error verifying token:', error);
    return { success: false, error };
  }
}

/**
 * Get user by Firebase UID
 */
export async function getUserByUid(uid: string) {
  try {
    const userRecord = await adminAuth.getUser(uid);
    return { success: true, user: userRecord };
  } catch (error) {
    console.error('Error fetching user:', error);
    return { success: false, error };
  }
}

/**
 * Delete user from Firebase Auth
 */
export async function deleteUser(uid: string) {
  try {
    await adminAuth.deleteUser(uid);
    return { success: true };
  } catch (error) {
    console.error('Error deleting user:', error);
    return { success: false, error };
  }
}
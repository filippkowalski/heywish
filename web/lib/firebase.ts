import { initializeApp, getApps } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getAnalytics, Analytics, isSupported } from 'firebase/analytics';

// Firebase configuration
const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || "AIzaSyA4xvIGQ482y_bojE2aKzzQ7BsZCpGYEm8",
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || "wishlist-app-v2.firebaseapp.com",
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "wishlist-app-v2",
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || "wishlist-app-v2.firebasestorage.app",
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || "100728931577",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || "1:100728931577:web:77333444301fa360fece28",
  measurementId: process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID || "G-BRDJHGM96Y"
};

// Initialize Firebase (only once)
const app = !getApps().length ? initializeApp(firebaseConfig) : getApps()[0];

// Initialize Firebase Auth
export const auth = getAuth(app);

// Analytics instance
let analytics: Analytics | null = null;

// Initialize Analytics (only after user consent and on client-side)
export async function initializeAnalytics(): Promise<Analytics | null> {
  if (typeof window === "undefined" || analytics) {
    return analytics;
  }

  try {
    const supported = await isSupported();
    if (supported) {
      analytics = getAnalytics(app);
      console.log("Firebase Analytics initialized");
    }
  } catch (error) {
    console.error("Firebase Analytics initialization failed:", error);
  }

  return analytics;
}

export { analytics };
export default app;
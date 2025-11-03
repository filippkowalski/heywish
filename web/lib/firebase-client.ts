import { initializeApp, getApp, getApps, type FirebaseApp } from "firebase/app";
import {
  getAuth,
  browserLocalPersistence,
  setPersistence,
  type Auth,
} from "firebase/auth";
import { firebaseConfig } from "./firebase-config";

function validateFirebaseConfig() {
  if (
    !firebaseConfig.apiKey ||
    !firebaseConfig.authDomain ||
    !firebaseConfig.projectId ||
    !firebaseConfig.appId
  ) {
    throw new Error(
      `Missing required Firebase configuration. Ensure NEXT_PUBLIC_FIREBASE_* environment variables are set in Cloudflare Pages. ` +
        `Got: apiKey=${!!firebaseConfig.apiKey}, authDomain=${!!firebaseConfig.authDomain}, projectId=${!!firebaseConfig.projectId}, appId=${!!firebaseConfig.appId}`,
    );
  }
}

let firebaseApp: FirebaseApp | null = null;
let authInstance: Auth | null = null;

export function getFirebaseApp(): FirebaseApp {
  if (firebaseApp) {
    return firebaseApp;
  }

  validateFirebaseConfig();
  firebaseApp = getApps().length ? getApp() : initializeApp(firebaseConfig);
  return firebaseApp;
}

export const RESERVATION_EMAIL_STORAGE_KEY = "jinnie.reservation.email";
export const RESERVATION_PENDING_STORAGE_KEY =
  "jinnie.reservation.pendingPayload";
export const RESERVATION_SESSION_STORAGE_KEY = "jinnie.reservation.session";

export type SessionType = "full" | "reservation";

export interface ReservationSession {
  type: SessionType;
  createdAt: number;
  expiresAt: number;
  email: string;
}

const SESSION_DURATION_MS = 48 * 60 * 60 * 1000; // 48 hours

/**
 * Store reservation session metadata
 */
export function setReservationSession(email: string): void {
  if (typeof window === "undefined") return;

  const now = Date.now();
  const session: ReservationSession = {
    type: "reservation",
    createdAt: now,
    expiresAt: now + SESSION_DURATION_MS,
    email,
  };

  localStorage.setItem(RESERVATION_SESSION_STORAGE_KEY, JSON.stringify(session));
}

/**
 * Get reservation session metadata
 */
export function getReservationSession(): ReservationSession | null {
  if (typeof window === "undefined") return null;

  const stored = localStorage.getItem(RESERVATION_SESSION_STORAGE_KEY);
  if (!stored) return null;

  try {
    return JSON.parse(stored) as ReservationSession;
  } catch {
    return null;
  }
}

/**
 * Check if reservation session has expired
 */
export function isReservationSessionExpired(): boolean {
  const session = getReservationSession();
  if (!session) return false;

  return Date.now() > session.expiresAt;
}

/**
 * Clear reservation session
 */
export function clearReservationSession(): void {
  if (typeof window === "undefined") return;

  localStorage.removeItem(RESERVATION_SESSION_STORAGE_KEY);
  localStorage.removeItem(RESERVATION_EMAIL_STORAGE_KEY);
  localStorage.removeItem(RESERVATION_PENDING_STORAGE_KEY);
}

export function getFirebaseAuth(): Auth {
  if (typeof window === "undefined") {
    throw new Error("Firebase Auth is only available in the browser.");
  }

  if (authInstance) {
    return authInstance;
  }

  const app = getFirebaseApp();
  const auth = getAuth(app);
  auth.languageCode = "en";

  setPersistence(auth, browserLocalPersistence).catch(() => {
    /* ignore persistence errors; fallback to default */
  });

  authInstance = auth;
  return authInstance;
}

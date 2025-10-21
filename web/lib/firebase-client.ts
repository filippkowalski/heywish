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

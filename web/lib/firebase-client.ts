import { initializeApp, getApp, getApps, type FirebaseApp } from "firebase/app";
import {
  getAuth,
  browserLocalPersistence,
  setPersistence,
  type Auth,
} from "firebase/auth";

const REQUIRED_ENV_KEYS = [
  "NEXT_PUBLIC_FIREBASE_API_KEY",
  "NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN",
  "NEXT_PUBLIC_FIREBASE_PROJECT_ID",
  "NEXT_PUBLIC_FIREBASE_APP_ID",
];

type FirebaseConfig = {
  apiKey: string;
  authDomain: string;
  projectId: string;
  appId: string;
  storageBucket?: string;
  messagingSenderId?: string;
  measurementId?: string;
};

function readFirebaseConfig(): FirebaseConfig {
  const env = process.env;
  const missing = REQUIRED_ENV_KEYS.filter((key) => !env[key]);

  if (missing.length > 0) {
    throw new Error(
      `Missing Firebase environment variables: ${missing.join(
        ", ",
      )}. Add them to .env.local.`,
    );
  }

  return {
    apiKey: env.NEXT_PUBLIC_FIREBASE_API_KEY as string,
    authDomain: env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN as string,
    projectId: env.NEXT_PUBLIC_FIREBASE_PROJECT_ID as string,
    appId: env.NEXT_PUBLIC_FIREBASE_APP_ID as string,
    storageBucket: env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
    measurementId: env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID,
  };
}

let firebaseApp: FirebaseApp | null = null;
let authInstance: Auth | null = null;

export function getFirebaseApp(): FirebaseApp {
  if (firebaseApp) {
    return firebaseApp;
  }

  const config = readFirebaseConfig();
  firebaseApp = getApps().length ? getApp() : initializeApp(config);
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

'use client';

import React, { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react';
import {
  User,
  signInWithPopup,
  signOut as firebaseSignOut,
  onIdTokenChanged,
  type AuthError,
} from 'firebase/auth';
import { auth, googleProvider, appleProvider } from '../firebase.client';
import { useRouter } from 'next/navigation';
import {
  getReservationSession,
  isReservationSessionExpired,
  clearReservationSession,
} from '../firebase-client';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'https://openai-rewrite.onrender.com/jinnie/v1';

interface BackendUser {
  id: string;
  username: string;
  full_name?: string | null;
  email: string;
  avatar_url?: string | null;
  bio?: string | null;
}

interface AuthContextType {
  user: User | null;
  backendUser: BackendUser | null;
  loading: boolean;
  isReservationSession: boolean;
  signInWithGoogle: () => Promise<void>;
  signInWithApple: () => Promise<void>;
  signOut: () => Promise<void>;
  refreshIdToken: () => Promise<string>;
  getIdToken: () => Promise<string | null>;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [backendUser, setBackendUser] = useState<BackendUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [isReservationSession, setIsReservationSession] = useState(false);
  const router = useRouter();

  // Cache refresh promise to prevent concurrent refreshes
  const refreshPromiseRef = useRef<Promise<string> | null>(null);

  // Track previous user state to detect sign in/out
  const prevUserRef = useRef<User | null>(null);

  // Listen to Firebase auth state changes
  useEffect(() => {
    const unsubscribe = onIdTokenChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        try {
          // Detect if this is a reservation session (email link auth without provider)
          const providerData = firebaseUser.providerData;
          const hasProvider = providerData.length > 0 &&
            (providerData[0].providerId === 'google.com' || providerData[0].providerId === 'apple.com');

          // Check reservation session status
          const reservationSession = getReservationSession();
          const isExpired = isReservationSessionExpired();

          // If user signed in with Google/Apple, clear any stale reservation session
          if (hasProvider && reservationSession !== null) {
            clearReservationSession();
          }

          // ONLY enforce expiry for reservation-only sessions (not Google/Apple)
          if (!hasProvider && isExpired) {
            clearReservationSession();
            await firebaseSignOut(auth);
            setUser(null);
            setBackendUser(null);
            setIsReservationSession(false);
            setLoading(false);
            return;
          }

          const isReservationOnly = !hasProvider && reservationSession !== null;

          // Store Firebase ID token in cookie for server-side access
          const token = await firebaseUser.getIdToken();
          const secure = window.location.protocol === 'https:' ? '; Secure' : '';
          document.cookie = `firebaseIdToken=${token}; path=/; max-age=3600; SameSite=Lax${secure}`;

          setUser(firebaseUser);
          setIsReservationSession(isReservationOnly);

          // Only sync with backend if NOT a reservation-only session
          if (!isReservationOnly) {
            // Determine sign-up method from provider data
            let signUpMethod = 'google'; // default
            if (providerData.length > 0) {
              const providerId = providerData[0].providerId;
              if (providerId === 'apple.com') {
                signUpMethod = 'apple';
              } else if (providerId === 'google.com') {
                signUpMethod = 'google';
              }
            }

            const response = await fetch(`${API_BASE_URL}/auth/sync`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`,
                'X-API-Version': '1.0',
              },
              body: JSON.stringify({
                signUpMethod,
                fullName: firebaseUser.displayName,
              }),
            });

            const data = await response.json();

            // Store backend user data
            if (data.user) {
              const backendUserData = {
                id: data.user.id,
                username: data.user.username,
                full_name: data.user.full_name,
                email: data.user.email,
                avatar_url: data.user.avatar_url,
                bio: data.user.bio,
              };
              setBackendUser(backendUserData);
            }
          } else {
            // For reservation sessions, don't set backend user
            setBackendUser(null);
          }
        } catch (error) {
          // Still set user even if backend sync fails
          setUser(firebaseUser);
          setIsReservationSession(false);
        }
      } else {
        // Clear cookie on sign out
        document.cookie = 'firebaseIdToken=; path=/; max-age=0';
        clearReservationSession();
        setUser(null);
        setBackendUser(null);
        setIsReservationSession(false);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // Cleanup stale cookies on mount if user isn't authenticated
  useEffect(() => {
    if (!loading && !user) {
      // Clear any stale cookies when there's no authenticated user
      document.cookie = 'firebaseIdToken=; path=/; max-age=0';
    }
  }, [loading, user]);

  // Refresh page when auth state changes (sign in/out) to update server-rendered content
  useEffect(() => {
    if (loading) return; // Don't refresh during initial load

    const prevUser = prevUserRef.current;
    const userChanged = (prevUser === null && user !== null) || (prevUser !== null && user === null);

    if (userChanged) {
      router.refresh();
    }

    prevUserRef.current = user;
  }, [user, loading, router]);

  // Redirect users without username to onboarding (continuous check)
  useEffect(() => {
    if (loading) return;
    if (!user || !backendUser) return;

    // If user is authenticated but doesn't have a username, redirect to onboarding
    if (!backendUser.username) {
      const currentPath = window.location.pathname;
      // Don't redirect if already on onboarding page
      if (currentPath !== '/onboarding') {
        router.push('/onboarding');
      }
    }
  }, [user, backendUser, loading, router]);

  // Sign in with Google
  const signInWithGoogle = useCallback(async () => {
    try {
      await signInWithPopup(auth, googleProvider);
      // User will be set by onIdTokenChanged listener
    } catch (error) {
      const authError = error as AuthError;

      // Handle specific error codes
      if (authError.code === 'auth/popup-closed-by-user') {
        throw new Error('Sign-in was cancelled. Please try again.');
      } else if (authError.code === 'auth/popup-blocked') {
        throw new Error('Pop-up was blocked by your browser. Please allow pop-ups and try again.');
      } else {
        throw new Error('Failed to sign in with Google. Please try again.');
      }
    }
  }, []);

  // Sign in with Apple
  const signInWithApple = useCallback(async () => {
    try {
      await signInWithPopup(auth, appleProvider);
      // User will be set by onIdTokenChanged listener
    } catch (error) {
      const authError = error as AuthError;

      // Handle specific error codes
      if (authError.code === 'auth/popup-closed-by-user') {
        throw new Error('Sign-in was cancelled. Please try again.');
      } else if (authError.code === 'auth/popup-blocked') {
        throw new Error('Pop-up was blocked by your browser. Please allow pop-ups and try again.');
      } else if (authError.code === 'auth/account-exists-with-different-credential') {
        throw new Error('An account already exists with the same email. Please sign in with the original provider.');
      } else {
        throw new Error('Failed to sign in with Apple. Please try again.');
      }
    }
  }, []);

  // Sign out
  const signOut = useCallback(async () => {
    try {
      clearReservationSession();
      await firebaseSignOut(auth);
      setUser(null);
      setBackendUser(null);
      setIsReservationSession(false);
    } catch (error) {
      throw new Error('Failed to sign out. Please try again.');
    }
  }, []);

  // Refresh ID token (concurrent-safe)
  const refreshIdToken = useCallback(async (): Promise<string> => {
    if (!user) {
      throw new Error('No user logged in');
    }

    // Return cached promise if refresh is already in progress
    if (refreshPromiseRef.current) {
      return refreshPromiseRef.current;
    }

    // Create and cache the refresh promise
    const promise = (async () => {
      try {
        const token = await user.getIdToken(true);
        return token;
      } finally {
        // Clear cache when done
        refreshPromiseRef.current = null;
      }
    })();

    refreshPromiseRef.current = promise;
    return promise;
  }, [user]);

  // Get current ID token without forcing refresh
  const getIdToken = useCallback(async (): Promise<string | null> => {
    if (!user) {
      return null;
    }
    try {
      return await user.getIdToken();
    } catch (error) {
      console.error('Failed to get ID token:', error);
      return null;
    }
  }, [user]);

  // Refresh user data from backend
  const refreshUser = useCallback(async () => {
    if (!user) {
      return;
    }

    try {
      const token = await user.getIdToken();

      // Determine sign-up method from provider data
      const providerData = user.providerData;
      let signUpMethod = 'google'; // default
      if (providerData.length > 0) {
        const providerId = providerData[0].providerId;
        if (providerId === 'apple.com') {
          signUpMethod = 'apple';
        } else if (providerId === 'google.com') {
          signUpMethod = 'google';
        }
      }

      const response = await fetch(`${API_BASE_URL}/auth/sync`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
          'X-API-Version': '1.0',
        },
        body: JSON.stringify({
          signUpMethod,
          fullName: user.displayName,
        }),
      });

      const data = await response.json();

      if (data.user) {
        const backendUserData = {
          id: data.user.id,
          username: data.user.username,
          full_name: data.user.full_name,
          email: data.user.email,
          avatar_url: data.user.avatar_url,
          bio: data.user.bio,
        };
        setBackendUser(backendUserData);
      }
    } catch (error) {
      console.error('Failed to refresh user data:', error);
    }
  }, [user]);

  const value: AuthContextType = {
    user,
    backendUser,
    loading,
    isReservationSession,
    signInWithGoogle,
    signInWithApple,
    signOut,
    refreshIdToken,
    getIdToken,
    refreshUser,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

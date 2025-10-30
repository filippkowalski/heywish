'use client';

import React, { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react';
import {
  User,
  signInWithPopup,
  signOut as firebaseSignOut,
  onIdTokenChanged,
  type AuthError,
} from 'firebase/auth';
import { auth, googleProvider } from '../firebase.client';
import { useRouter } from 'next/navigation';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'https://openai-rewrite.onrender.com/jinnie/v1';

interface BackendUser {
  id: string;
  username: string;
  fullName?: string | null;
  email: string;
  avatarUrl?: string | null;
}

interface AuthContextType {
  user: User | null;
  backendUser: BackendUser | null;
  loading: boolean;
  signInWithGoogle: () => Promise<void>;
  signOut: () => Promise<void>;
  refreshIdToken: () => Promise<string>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [backendUser, setBackendUser] = useState<BackendUser | null>(null);
  const [loading, setLoading] = useState(true);
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
          // Sync user with backend
          const token = await firebaseUser.getIdToken();

          // Store Firebase ID token in cookie for server-side access
          // Set secure flag in production, httpOnly cannot be set via document.cookie
          const secure = window.location.protocol === 'https:' ? '; Secure' : '';
          document.cookie = `firebaseIdToken=${token}; path=/; max-age=3600; SameSite=Lax${secure}`;

          const response = await fetch(`${API_BASE_URL}/auth/sync`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`,
              'X-API-Version': '1.0',
            },
            body: JSON.stringify({
              signUpMethod: 'google',
            }),
          });

          const data = await response.json();

          // Store both Firebase user and backend user data
          setUser(firebaseUser);
          if (data.user) {
            const backendUserData = {
              id: data.user.id,
              username: data.user.username,
              fullName: data.user.full_name || data.user.fullName,
              email: data.user.email,
              avatarUrl: data.user.avatar_url || data.user.avatarUrl,
            };
            setBackendUser(backendUserData);
          }
        } catch (error) {
          // Still set user even if backend sync fails
          setUser(firebaseUser);
        }
      } else {
        // Clear cookie on sign out
        document.cookie = 'firebaseIdToken=; path=/; max-age=0';
        setUser(null);
        setBackendUser(null);
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

  // Sign out
  const signOut = useCallback(async () => {
    try {
      await firebaseSignOut(auth);
      setUser(null);
      setBackendUser(null);
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

  const value: AuthContextType = {
    user,
    backendUser,
    loading,
    signInWithGoogle,
    signOut,
    refreshIdToken,
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

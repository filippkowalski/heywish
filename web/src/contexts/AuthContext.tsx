'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import {
  User,
  signInAnonymously,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signInWithPopup,
  GoogleAuthProvider,
  signOut,
  onAuthStateChanged,
  linkWithCredential,
  EmailAuthProvider,
} from 'firebase/auth';
import { auth } from '@/lib/firebase/config';
import axios from 'axios';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  error: string | null;
  dbUser: any | null;
  signInAnonymous: () => Promise<void>;
  signInWithEmail: (email: string, password: string) => Promise<void>;
  signUpWithEmail: (email: string, password: string, username?: string) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  upgradeAnonymousAccount: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  refreshDbUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [dbUser, setDbUser] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Sync user with database
  const syncUserWithDatabase = async (firebaseUser: User, additionalData?: any) => {
    try {
      const token = await firebaseUser.getIdToken();
      const response = await axios.post('/api/auth/sync', {
        firebaseToken: token,
        ...additionalData,
      });
      setDbUser(response.data.user);
      return response.data;
    } catch (error) {
      console.error('Error syncing user with database:', error);
      throw error;
    }
  };

  // Sign in anonymously
  const signInAnonymous = async () => {
    try {
      setError(null);
      const result = await signInAnonymously(auth);
      await syncUserWithDatabase(result.user);
    } catch (error: any) {
      setError(error.message);
      throw error;
    }
  };

  // Sign in with email
  const signInWithEmail = async (email: string, password: string) => {
    try {
      setError(null);
      const result = await signInWithEmailAndPassword(auth, email, password);
      await syncUserWithDatabase(result.user);
    } catch (error: any) {
      setError(error.message);
      throw error;
    }
  };

  // Sign up with email
  const signUpWithEmail = async (email: string, password: string, username?: string) => {
    try {
      setError(null);
      const result = await createUserWithEmailAndPassword(auth, email, password);
      await syncUserWithDatabase(result.user, { username });
    } catch (error: any) {
      setError(error.message);
      throw error;
    }
  };

  // Sign in with Google
  const signInWithGoogle = async () => {
    try {
      setError(null);
      const provider = new GoogleAuthProvider();
      const result = await signInWithPopup(auth, provider);
      await syncUserWithDatabase(result.user);
    } catch (error: any) {
      setError(error.message);
      throw error;
    }
  };

  // Upgrade anonymous account
  const upgradeAnonymousAccount = async (email: string, password: string) => {
    try {
      setError(null);
      if (!user || !user.isAnonymous) {
        throw new Error('No anonymous user to upgrade');
      }
      
      const credential = EmailAuthProvider.credential(email, password);
      const result = await linkWithCredential(user, credential);
      await syncUserWithDatabase(result.user);
    } catch (error: any) {
      setError(error.message);
      throw error;
    }
  };

  // Logout
  const logout = async () => {
    try {
      setError(null);
      await signOut(auth);
      setDbUser(null);
    } catch (error: any) {
      setError(error.message);
      throw error;
    }
  };

  // Refresh database user
  const refreshDbUser = async () => {
    if (user) {
      await syncUserWithDatabase(user);
    }
  };

  // Initialize auth state
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      setUser(firebaseUser);
      
      if (firebaseUser) {
        try {
          await syncUserWithDatabase(firebaseUser);
        } catch (error) {
          console.error('Error syncing user on auth change:', error);
        }
      } else {
        setDbUser(null);
        // Automatically sign in anonymously when no user
        try {
          await signInAnonymous();
        } catch (error) {
          console.error('Error signing in anonymously:', error);
        }
      }
      
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const value = {
    user,
    loading,
    error,
    dbUser,
    signInAnonymous,
    signInWithEmail,
    signUpWithEmail,
    signInWithGoogle,
    upgradeAnonymousAccount,
    logout,
    refreshDbUser,
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
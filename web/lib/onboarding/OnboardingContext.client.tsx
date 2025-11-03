'use client';

import React, { createContext, useContext, useState, useCallback } from 'react';
import type { OnboardingData, OnboardingStep } from './constants';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'https://openai-rewrite.onrender.com/jinnie/v1';

interface UsernameCheckResult {
  available: boolean;
  checking: boolean;
  error?: string;
  suggestions?: string[];
}

interface OnboardingContextType {
  step: OnboardingStep;
  data: OnboardingData;
  usernameCheck: UsernameCheckResult;
  isSubmitting: boolean;
  error?: string;

  // Actions
  setStep: (step: OnboardingStep) => void;
  updateData: (key: keyof OnboardingData, value: any) => void;
  checkUsernameAvailability: (username: string) => Promise<void>;
  completeOnboarding: () => Promise<boolean>;
  resetOnboarding: () => void;
}

const OnboardingContext = createContext<OnboardingContextType | undefined>(undefined);

export function OnboardingProvider({ children }: { children: React.ReactNode }) {
  const [step, setStep] = useState<OnboardingStep>('interests');
  const [data, setData] = useState<OnboardingData>({});
  const [usernameCheck, setUsernameCheck] = useState<UsernameCheckResult>({
    available: false,
    checking: false,
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string>();

  // Debounced username check
  let usernameCheckTimeout: NodeJS.Timeout;

  const updateData = useCallback((key: keyof OnboardingData, value: any) => {
    setData((prev) => ({ ...prev, [key]: value }));
  }, []);

  const checkUsernameAvailability = useCallback(async (username: string) => {
    if (!username || username.length < 3) {
      setUsernameCheck({ available: false, checking: false });
      return;
    }

    // Clear previous timeout
    if (usernameCheckTimeout) {
      clearTimeout(usernameCheckTimeout);
    }

    setUsernameCheck({ available: false, checking: true });

    // Debounce for 500ms
    usernameCheckTimeout = setTimeout(async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/auth/check-username/${username.toLowerCase()}`, {
          method: 'GET',
          headers: {
            'X-API-Version': '1.0',
          },
        });

        const result = await response.json();

        if (response.ok) {
          setUsernameCheck({
            available: result.available,
            checking: false,
            suggestions: result.suggestions || [],
          });
        } else {
          setUsernameCheck({
            available: false,
            checking: false,
            error: result.error?.message || 'Failed to check username',
          });
        }
      } catch (err) {
        setUsernameCheck({
          available: false,
          checking: false,
          error: 'Network error. Please try again.',
        });
      }
    }, 500);
  }, []);

  const completeOnboarding = useCallback(async (): Promise<boolean> => {
    setIsSubmitting(true);
    setError(undefined);

    try {
      // Get Firebase ID token from auth context
      const auth = await import('firebase/auth');
      const { auth: firebaseAuth } = await import('../firebase.client');
      const user = auth.getAuth(firebaseAuth).currentUser;

      if (!user) {
        throw new Error('No authenticated user');
      }

      const token = await user.getIdToken();

      // Submit onboarding data to backend
      const response = await fetch(`${API_BASE_URL}/users/profile`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
          'X-API-Version': '1.0',
        },
        body: JSON.stringify({
          username: data.username?.toLowerCase(),
          birthdate: data.birthdate,
          gender: data.gender,
          shopping_interests: data.shopping_interests,
        }),
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error?.message || 'Failed to complete onboarding');
      }

      setIsSubmitting(false);
      return true;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to complete onboarding';
      setError(message);
      setIsSubmitting(false);
      return false;
    }
  }, [data]);

  const resetOnboarding = useCallback(() => {
    setStep('interests');
    setData({});
    setUsernameCheck({ available: false, checking: false });
    setIsSubmitting(false);
    setError(undefined);
  }, []);

  const value: OnboardingContextType = {
    step,
    data,
    usernameCheck,
    isSubmitting,
    error,
    setStep,
    updateData,
    checkUsernameAvailability,
    completeOnboarding,
    resetOnboarding,
  };

  return <OnboardingContext.Provider value={value}>{children}</OnboardingContext.Provider>;
}

export function useOnboarding() {
  const context = useContext(OnboardingContext);
  if (context === undefined) {
    throw new Error('useOnboarding must be used within an OnboardingProvider');
  }
  return context;
}

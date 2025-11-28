'use client';

import { OnboardingProvider, useOnboarding } from '@/lib/onboarding/OnboardingContext.client';
import { ShoppingInterestsStep } from '@/components/onboarding/ShoppingInterestsStep.client';
import { ProfileDetailsStep } from '@/components/onboarding/ProfileDetailsStep.client';
import { UsernameStep } from '@/components/onboarding/UsernameStep.client';
import { CompletionStep } from '@/components/onboarding/CompletionStep.client';
import { useAuth } from '@/lib/auth/AuthContext.client';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

export const runtime = 'edge';

function OnboardingContent() {
  const { step } = useOnboarding();
  const { user, backendUser, loading } = useAuth();
  const router = useRouter();

  // Redirect if not authenticated
  useEffect(() => {
    if (!loading && !user) {
      router.push('/');
    }
  }, [user, loading, router]);

  // Redirect if already has username (onboarding complete)
  useEffect(() => {
    if (!loading && backendUser?.username) {
      router.push('/');
    }
  }, [backendUser, loading, router]);

  // Show loading while checking auth
  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="w-8 h-8 border-4 border-gray-200 border-t-black rounded-full animate-spin" />
      </div>
    );
  }

  // Don't render if not authenticated
  if (!user) {
    return null;
  }

  // Render the appropriate step
  switch (step) {
    case 'interests':
      return <ShoppingInterestsStep />;
    case 'profile':
      return <ProfileDetailsStep />;
    case 'username':
      return <UsernameStep />;
    case 'complete':
      return <CompletionStep />;
    default:
      return <ShoppingInterestsStep />;
  }
}

export default function OnboardingPage() {
  return (
    <OnboardingProvider>
      <OnboardingContent />
    </OnboardingProvider>
  );
}

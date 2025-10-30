'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth/AuthContext.client';
import { SignInModal } from '@/components/auth/SignInModal.client';
import { Loader2 } from 'lucide-react';

export function UseWebVersionButton() {
  const [showSignIn, setShowSignIn] = useState(false);
  const { user, backendUser, loading } = useAuth();
  const router = useRouter();

  const handleClick = () => {
    // If user is already signed in, redirect to their profile
    if (user && backendUser?.username) {
      router.push(`/${backendUser.username}`);
    } else {
      // Otherwise, show sign-in modal
      setShowSignIn(true);
    }
  };

  return (
    <>
      <button
        onClick={handleClick}
        disabled={loading}
        className="inline-flex items-center justify-center rounded-xl border px-8 py-3 text-base font-semibold shadow-sm transition-all hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed"
        style={{
          borderColor: 'rgba(0,0,0,0.2)',
          backgroundColor: 'white',
          color: '#000'
        }}
      >
        {loading ? (
          <>
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            Loading...
          </>
        ) : user ? (
          'Go to My Profile'
        ) : (
          'Use Web Version'
        )}
      </button>

      <SignInModal open={showSignIn} onOpenChange={setShowSignIn} />
    </>
  );
}

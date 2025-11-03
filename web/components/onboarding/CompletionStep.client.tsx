'use client';

import { Button } from '@/components/ui/button';
import { useOnboarding } from '@/lib/onboarding/OnboardingContext.client';
import { useState } from 'react';
import { toast } from 'sonner';

export function CompletionStep() {
  const { data } = useOnboarding();
  const [copying, setCopying] = useState(false);

  const profileUrl = `${window.location.origin}/${data.username}`;

  const handleCopyLink = async () => {
    setCopying(true);
    try {
      await navigator.clipboard.writeText(profileUrl);
      toast.success('Profile link copied!');
    } catch {
      toast.error('Failed to copy link');
    } finally {
      setCopying(false);
    }
  };

  const handleContinue = () => {
    // Force full page reload to ensure auth state is refreshed
    // This prevents the infinite redirect loop by re-syncing with backend
    window.location.href = '/';
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen p-6 bg-gradient-to-b from-white to-gray-50">
      <div className="w-full max-w-md space-y-8 text-center">
        {/* Success Icon */}
        <div className="flex justify-center">
          <div className="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center">
            <svg
              className="w-12 h-12 text-green-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M5 13l4 4L19 7"
              />
            </svg>
          </div>
        </div>

        {/* Header */}
        <div className="space-y-3">
          <h1 className="text-4xl font-bold tracking-tight">Welcome to Jinnie!</h1>
          <p className="text-lg text-gray-600">
            Your profile is ready. Start creating your wishlists and sharing them with friends.
          </p>
        </div>

        {/* Profile Link */}
        <div className="bg-white rounded-2xl border-2 border-gray-200 p-6 space-y-4">
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-700">Your profile link</p>
            <div className="flex items-center gap-2">
              <div className="flex-1 bg-gray-50 rounded-lg px-4 py-3 text-left">
                <p className="text-sm text-gray-900 font-mono break-all">
                  jinnie.app/<span className="font-semibold">{data.username}</span>
                </p>
              </div>
              <Button
                onClick={handleCopyLink}
                variant="outline"
                size="sm"
                disabled={copying}
                className="shrink-0 h-11 px-4"
              >
                {copying ? (
                  <div className="w-4 h-4 border-2 border-gray-300 border-t-gray-600 rounded-full animate-spin" />
                ) : (
                  <svg
                    className="w-4 h-4"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
                    />
                  </svg>
                )}
              </Button>
            </div>
          </div>

          <p className="text-xs text-gray-500">
            Share this link with friends so they can see your wishlists
          </p>
        </div>

        {/* Stats */}
        {data.shopping_interests && data.shopping_interests.length > 0 && (
          <div className="bg-gray-50 rounded-xl p-4">
            <p className="text-sm text-gray-600">
              You selected{' '}
              <span className="font-semibold text-gray-900">
                {data.shopping_interests.length}
              </span>{' '}
              {data.shopping_interests.length === 1 ? 'interest' : 'interests'}
            </p>
          </div>
        )}

        {/* Action */}
        <div className="pt-4">
          <Button
            onClick={handleContinue}
            className="w-full h-14 text-base bg-black hover:bg-gray-800"
          >
            Go to Home
          </Button>
        </div>

        {/* Progress indicator - all filled */}
        <div className="flex justify-center gap-2 pt-4">
          <div className="w-2 h-2 rounded-full bg-black" />
          <div className="w-2 h-2 rounded-full bg-black" />
          <div className="w-2 h-2 rounded-full bg-black" />
          <div className="w-2 h-2 rounded-full bg-black" />
        </div>
      </div>
    </div>
  );
}

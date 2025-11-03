'use client';

export const runtime = 'edge';

import { useEffect } from 'react';
import { useParams } from 'next/navigation';
import { detectPlatform, getAppStoreUrl } from '@/lib/platform-detection';

/**
 * Deep link landing page for /@username/follow
 *
 * This page is reached when:
 * 1. iOS tries universal link but app not installed
 * 2. User manually navigates here
 *
 * Flow:
 * 1. Page loads (triggered by universal link attempt)
 * 2. Wait briefly to see if app opened (visibilitychange)
 * 3. If still here after timeout, redirect to app store
 */
export default function FollowDeepLinkPage() {
  const params = useParams();
  const username = params?.username as string;

  useEffect(() => {
    // Detect if app opened (page went to background)
    let appOpened = false;

    const handleVisibilityChange = () => {
      if (document.hidden) {
        appOpened = true;
      }
    };

    const handlePageHide = () => {
      appOpened = true;
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('pagehide', handlePageHide);

    // Wait 1.5 seconds to see if app opened
    const timeout = setTimeout(() => {
      if (!appOpened) {
        // App didn't open, redirect to app store
        const platform = detectPlatform();
        const appStoreUrl = getAppStoreUrl(platform.platform, 'profile-follow-deeplink');
        window.location.href = appStoreUrl;
      }
    }, 1500);

    return () => {
      clearTimeout(timeout);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('pagehide', handlePageHide);
    };
  }, []);

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <div className="max-w-md w-full text-center space-y-4">
        <div className="animate-pulse">
          <div className="w-16 h-16 bg-black rounded-full mx-auto mb-4 flex items-center justify-center">
            <svg
              className="w-8 h-8 text-white"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 4v16m8-8H4"
              />
            </svg>
          </div>
        </div>
        <h1 className="text-2xl font-semibold">Opening Jinnie...</h1>
        <p className="text-muted-foreground">
          Follow {username} in the Jinnie app
        </p>
        <p className="text-sm text-muted-foreground">
          If the app doesn&apos;t open, you&apos;ll be redirected to download it.
        </p>
      </div>
    </div>
  );
}

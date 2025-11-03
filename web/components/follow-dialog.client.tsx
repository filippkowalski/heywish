'use client';

import { useState, useEffect } from 'react';
import { UserPlus } from 'lucide-react';
import Image from 'next/image';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { detectPlatform, getAppStoreUrl, type Platform } from '@/lib/platform-detection';

interface FollowDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  username: string;
  avatarUrl?: string | null;
}

/**
 * Dialog shown when user clicks Follow button
 *
 * Strategy:
 * 1. Attempt to open deep link to profile in mobile app
 * 2. Wait 2 seconds to see if app opened
 * 3. If timeout expires, redirect to app store
 */
export function FollowDialog({
  open,
  onOpenChange,
  username,
  avatarUrl,
}: FollowDialogProps) {
  const [platform, setPlatform] = useState<Platform | null>(null);
  const [attemptedDeepLink, setAttemptedDeepLink] = useState(false);
  const [isRedirecting, setIsRedirecting] = useState(false);

  // Detect platform synchronously on mount
  useEffect(() => {
    const info = detectPlatform();
    setPlatform(info.platform);
  }, []);

  // Reset state when dialog opens/closes
  useEffect(() => {
    if (open) {
      setAttemptedDeepLink(false);
      setIsRedirecting(false);
    }
  }, [open]);

  // No useEffect needed - iOS handles via /@username/follow page
  // Android handles via Intent URL fallback

  const handleOpenInApp = () => {
    if (!platform) {
      // Platform not detected yet, should not happen because button is disabled
      return;
    }

    setAttemptedDeepLink(true);

    const appStoreUrl = getAppStoreUrl(platform, 'profile-follow');

    // Detect if we're on mobile
    const isMobile = platform === 'ios' || platform === 'android';

    if (!isMobile) {
      // Desktop: Just go straight to app store
      setIsRedirecting(true);
      window.location.href = appStoreUrl;
      return;
    }

    // Mobile: Platform-specific deep link strategies
    if (platform === 'ios') {
      // iOS: Use foreground navigation with universal link
      // The /@username/follow page will handle fallback to App Store
      const universalLink = `https://jinnie.co/@${username}/follow`;

      // Must use top-level navigation for universal links to work (iOS 13+ requirement)
      window.location.href = universalLink;

      // If app installed: iOS opens app via Associated Domains
      // If not installed: Loads /@username/follow page which redirects to App Store
    } else if (platform === 'android') {
      // Android: Try custom scheme first, with manual fallback handling
      const customSchemeUrl = `com.wishlists.gifts://profile/${username}?action=follow`;

      let appOpened = false;

      const handleVisibilityChange = () => {
        if (document.hidden) {
          appOpened = true;
        }
      };

      document.addEventListener('visibilitychange', handleVisibilityChange);

      // Attempt to open the app
      window.location.href = customSchemeUrl;

      // If app doesn't open within 2 seconds, redirect to Play Store
      setTimeout(() => {
        document.removeEventListener('visibilitychange', handleVisibilityChange);
        if (!appOpened) {
          setIsRedirecting(true);
          window.location.href = appStoreUrl;
        }
      }, 2000);
    }
  };

  const isPlatformDetected = platform !== null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          {/* User Avatar */}
          {avatarUrl && (
            <div className="mx-auto mb-4">
              <img
                src={avatarUrl}
                alt={username}
                className="w-20 h-20 rounded-full object-cover border-2 border-gray-200"
              />
            </div>
          )}

          <DialogTitle className="text-center text-2xl">
            Follow @{username} in Jinnie
          </DialogTitle>
          <DialogDescription className="text-center text-base">
            Following is only available in the Jinnie mobile app. Connect with friends, see their wishlists, and never miss a birthday again. Web support coming soon!
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3 px-6 py-4">
          {/* Primary CTA - Open in App */}
          <button
            onClick={handleOpenInApp}
            disabled={!isPlatformDetected || attemptedDeepLink || isRedirecting}
            className="w-full px-6 py-3 bg-black text-white text-base font-semibold rounded-lg hover:bg-gray-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            <UserPlus className="w-5 h-5" />
            {!isPlatformDetected ? 'Loading...' : isRedirecting ? 'Redirecting...' : attemptedDeepLink ? 'Opening App...' : 'Open in Jinnie App'}
          </button>

          {/* App Store Badges */}
          <div className="flex flex-col items-center gap-3 sm:flex-row sm:justify-center pt-2">
            <a
              href="https://apps.apple.com/app/id6754384455?ref=jinnie-follow"
              className="block transition-transform hover:scale-105"
              style={{ height: '80px', display: 'flex', alignItems: 'center' }}
            >
              <Image
                src="/badges/app-store-badge.svg"
                alt="Download on the App Store"
                width={240}
                height={80}
                className="h-[54px] w-auto"
              />
            </a>
            <a
              href="https://play.google.com/store/apps/details?id=com.wishlists.gifts&ref=jinnie-follow"
              className="block transition-transform hover:scale-105"
              style={{ height: '80px', display: 'flex', alignItems: 'center' }}
            >
              <Image
                src="/badges/google-play-badge.png"
                alt="Get it on Google Play"
                width={240}
                height={80}
                className="h-[80px] w-auto"
              />
            </a>
          </div>

          {/* Features */}
          <div className="mt-6 pt-6 border-t border-gray-200">
            <div className="space-y-2.5 text-sm text-gray-600">
              <div className="flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-black" />
                <span>Follow friends and see their wishlists</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-black" />
                <span>Get notified about birthdays and special occasions</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-black" />
                <span>Coordinate gifts without spoiling surprises</span>
              </div>
            </div>
          </div>

          {/* Footer note */}
          <p className="text-center text-xs text-gray-500 pt-4">
            Free to download • Available on iOS and Android
          </p>
        </div>
      </DialogContent>
    </Dialog>
  );
}

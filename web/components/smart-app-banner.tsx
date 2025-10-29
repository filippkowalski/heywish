'use client';

import { useEffect, useState } from 'react';
import { X } from 'lucide-react';
import {
  detectPlatform,
  getAppStoreUrl,
  isBannerDismissed,
  dismissBanner,
  type PlatformInfo,
} from '@/lib/platform-detection';

export function SmartAppBanner() {
  const [platformInfo, setPlatformInfo] = useState<PlatformInfo | null>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    // Detect platform on client-side only
    const info = detectPlatform();
    setPlatformInfo(info);

    // Show banner if platform requires it and hasn't been dismissed
    if (info.shouldShowBanner && !isBannerDismissed()) {
      setIsVisible(true);
    }
  }, []);

  const handleDismiss = () => {
    dismissBanner();
    setIsVisible(false);
  };

  const handleGetApp = () => {
    if (platformInfo) {
      window.location.href = getAppStoreUrl(platformInfo.platform);
    }
  };

  if (!isVisible || !platformInfo?.shouldShowBanner) {
    return null;
  }

  return (
    <>
      {/* Banner */}
      <div className="fixed top-0 left-0 right-0 z-50 bg-white border-b border-gray-200 shadow-md">
        {/* Colorful top accent bar for contrast */}
        <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500" />

        <div className="max-w-7xl mx-auto px-4 py-3 relative">
          <div className="flex items-center justify-between gap-3">
            {/* App Icon & Info */}
            <div className="flex items-center gap-3 min-w-0 flex-1">
              {/* App Icon */}
              <div className="flex-shrink-0">
                <img
                  src="/apple-touch-icon.png"
                  alt="Jinnie"
                  className="w-12 h-12 rounded-xl"
                />
              </div>

              {/* App Info */}
              <div className="min-w-0 flex-1">
                <div className="text-sm font-semibold text-black truncate">
                  Jinnie
                </div>
                <div className="text-xs text-gray-600 truncate">
                  Create and manage your wishlists
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="flex items-center gap-2 flex-shrink-0">
              {/* Get App Button */}
              <button
                onClick={handleGetApp}
                className="px-5 py-2 bg-black text-white text-sm font-semibold rounded-full hover:bg-gray-800 transition-colors"
              >
                Get App
              </button>

              {/* Close Button */}
              <button
                onClick={handleDismiss}
                className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
                aria-label="Dismiss banner"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Spacer to prevent content from being hidden under fixed banner */}
      <div className="h-[72px]" aria-hidden="true" />
    </>
  );
}

'use client';

import { useEffect, useState } from 'react';
import { X, Sparkles, Heart, Gift } from 'lucide-react';
import {
  detectPlatform,
  getAppStoreUrl,
  isBottomSheetDismissed,
  dismissBottomSheet,
  type Platform,
} from '@/lib/platform-detection';

export function AppDownloadBottomSheet() {
  const [platform, setPlatform] = useState<Platform>('other');
  const [isVisible, setIsVisible] = useState(false);
  const [isAnimating, setIsAnimating] = useState(false);

  useEffect(() => {
    const info = detectPlatform();
    setPlatform(info.platform);

    // Show bottom sheet if platform requires it and hasn't been dismissed
    if (info.shouldShowBanner && !isBottomSheetDismissed()) {
      // Delay showing the bottom sheet slightly for better UX
      const timer = setTimeout(() => {
        setIsVisible(true);
        // Trigger animation after mount
        requestAnimationFrame(() => {
          setIsAnimating(true);
        });
      }, 1500); // Show after 1.5 seconds

      return () => clearTimeout(timer);
    }
  }, []);

  const handleDismiss = () => {
    dismissBottomSheet();
    setIsAnimating(false);
    // Wait for animation to complete before hiding
    setTimeout(() => {
      setIsVisible(false);
    }, 300);
  };

  const handleGetApp = () => {
    const url = getAppStoreUrl(platform);
    window.location.href = url;
    dismissBottomSheet();
  };

  if (!isVisible) {
    return null;
  }

  const platformName = platform === 'android' ? 'Android' : 'iOS';

  return (
    <>
      {/* Backdrop overlay */}
      <div
        className={`fixed inset-0 bg-black/50 backdrop-blur-sm z-[100] transition-opacity duration-300 ${
          isAnimating ? 'opacity-100' : 'opacity-0'
        }`}
        onClick={handleDismiss}
      />

      {/* Bottom sheet */}
      <div
        className={`fixed bottom-0 left-0 right-0 z-[101] bg-white rounded-t-3xl shadow-2xl transition-transform duration-300 ease-out ${
          isAnimating ? 'translate-y-0' : 'translate-y-full'
        }`}
      >
        {/* Handle bar */}
        <div className="flex justify-center pt-3 pb-2">
          <div className="w-12 h-1.5 bg-gray-300 rounded-full" />
        </div>

        <div className="px-6 pb-8 pt-4">
          {/* Close button */}
          <button
            onClick={handleDismiss}
            className="absolute right-4 top-4 p-2 text-gray-400 hover:text-gray-600 transition-colors rounded-full hover:bg-gray-100"
            aria-label="Dismiss"
          >
            <X className="w-5 h-5" />
          </button>

          {/* Content */}
          <div className="flex flex-col items-center text-center">
            {/* App Icon */}
            <img
              src="/apple-touch-icon.png"
              alt="Jinnie"
              className="w-20 h-20 rounded-2xl shadow-lg mb-4"
            />

            {/* Title */}
            <h3 className="text-2xl font-bold text-black mb-2">
              Get Jinnie for {platformName}
            </h3>

            {/* Description */}
            <p className="text-gray-600 text-base mb-6 max-w-sm">
              Create wishlists, share with friends, and make gift-giving magical
            </p>

            {/* Features */}
            <div className="flex items-center justify-center gap-6 mb-6 text-sm">
              <div className="flex flex-col items-center gap-1.5">
                <div className="w-10 h-10 rounded-full bg-blue-50 flex items-center justify-center">
                  <Heart className="w-5 h-5 text-blue-600" />
                </div>
                <span className="text-gray-700 font-medium">Create</span>
              </div>
              <div className="flex flex-col items-center gap-1.5">
                <div className="w-10 h-10 rounded-full bg-purple-50 flex items-center justify-center">
                  <Sparkles className="w-5 h-5 text-purple-600" />
                </div>
                <span className="text-gray-700 font-medium">Share</span>
              </div>
              <div className="flex flex-col items-center gap-1.5">
                <div className="w-10 h-10 rounded-full bg-pink-50 flex items-center justify-center">
                  <Gift className="w-5 h-5 text-pink-600" />
                </div>
                <span className="text-gray-700 font-medium">Gift</span>
              </div>
            </div>

            {/* Download button */}
            <button
              onClick={handleGetApp}
              className="w-full max-w-sm px-6 py-4 bg-black text-white text-lg font-semibold rounded-2xl hover:bg-gray-800 transition-colors shadow-lg"
            >
              Download Free App
            </button>

            {/* Footer note */}
            <p className="text-gray-400 text-xs mt-4">
              Free to download • No ads • Privacy first
            </p>
          </div>
        </div>
      </div>
    </>
  );
}

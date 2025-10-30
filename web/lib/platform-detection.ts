/**
 * Platform detection utility for smart app banner
 * Detects device type, OS, and browser for app download prompts
 */

export type Platform = 'ios' | 'android' | 'other';
export type Browser = 'safari' | 'chrome' | 'firefox' | 'other';

export interface PlatformInfo {
  platform: Platform;
  browser: Browser;
  isStandalone: boolean;
  shouldShowBanner: boolean;
}

/**
 * Detects the user's platform and browser
 * Only works on client-side (requires window.navigator)
 */
export function detectPlatform(): PlatformInfo {
  if (typeof window === 'undefined') {
    return {
      platform: 'other',
      browser: 'other',
      isStandalone: false,
      shouldShowBanner: false,
    };
  }

  const userAgent = window.navigator.userAgent.toLowerCase();
  const standalone = ('standalone' in window.navigator && (window.navigator as { standalone?: boolean }).standalone === true) ||
                     window.matchMedia('(display-mode: standalone)').matches;

  // Detect iOS
  const isIOS = /iphone|ipad|ipod/.test(userAgent);

  // Detect Android
  const isAndroid = /android/.test(userAgent);

  // Detect browser
  let browser: Browser = 'other';
  if (/safari/.test(userAgent) && !/chrome/.test(userAgent)) {
    browser = 'safari';
  } else if (/chrome/.test(userAgent)) {
    browser = 'chrome';
  } else if (/firefox/.test(userAgent)) {
    browser = 'firefox';
  }

  // Determine platform
  let platform: Platform = 'other';
  if (isIOS) {
    platform = 'ios';
  } else if (isAndroid) {
    platform = 'android';
  }

  // Should show banner if:
  // 1. On iOS but NOT in Safari (Safari has native smart banner)
  // 2. On Android
  // 3. NOT already running as standalone/PWA
  const shouldShowBanner =
    !standalone &&
    ((platform === 'ios' && browser !== 'safari') || platform === 'android');

  return {
    platform,
    browser,
    isStandalone: standalone,
    shouldShowBanner,
  };
}

/**
 * Gets the appropriate app store URL based on platform with optional ref parameter
 * @param platform - The platform (ios, android, or other)
 * @param ref - Optional referral parameter to track download source (e.g., 'landing', 'private_profile', 'banner')
 */
export function getAppStoreUrl(platform: Platform, ref?: string): string {
  const baseUrls = {
    ios: 'https://apps.apple.com/app/id6754384455',
    android: 'https://play.google.com/store/apps/details?id=com.wishlists.gifts',
  };

  let url = platform === 'android' ? baseUrls.android : baseUrls.ios;

  // Add ref parameter if provided
  if (ref) {
    const separator = url.includes('?') ? '&' : '?';
    url += `${separator}ref=${encodeURIComponent(ref)}`;
  }

  return url;
}

/**
 * Banner dismissal management using localStorage
 */
const BANNER_DISMISSED_KEY = 'jinnie_app_banner_dismissed';
const BANNER_DISMISSED_DURATION = 7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds

export function isBannerDismissed(): boolean {
  if (typeof window === 'undefined') return false;

  try {
    const dismissedAt = localStorage.getItem(BANNER_DISMISSED_KEY);
    if (!dismissedAt) return false;

    const dismissedTime = parseInt(dismissedAt, 10);
    const now = Date.now();

    // Check if 7 days have passed since dismissal
    return (now - dismissedTime) < BANNER_DISMISSED_DURATION;
  } catch {
    // localStorage might be disabled
    return false;
  }
}

export function dismissBanner(): void {
  if (typeof window === 'undefined') return;

  try {
    localStorage.setItem(BANNER_DISMISSED_KEY, Date.now().toString());
  } catch {
    // localStorage might be disabled
    console.warn('Failed to save banner dismissal state');
  }
}

/**
 * Bottom sheet dismissal management using localStorage
 * Shows once per week on website entry
 */
const BOTTOM_SHEET_DISMISSED_KEY = 'jinnie_app_bottom_sheet_dismissed';
const BOTTOM_SHEET_DISMISSED_DURATION = 7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds

export function isBottomSheetDismissed(): boolean {
  if (typeof window === 'undefined') return false;

  try {
    const dismissedAt = localStorage.getItem(BOTTOM_SHEET_DISMISSED_KEY);
    if (!dismissedAt) return false;

    const dismissedTime = parseInt(dismissedAt, 10);
    const now = Date.now();

    // Check if 7 days have passed since dismissal
    return (now - dismissedTime) < BOTTOM_SHEET_DISMISSED_DURATION;
  } catch {
    // localStorage might be disabled
    return false;
  }
}

export function dismissBottomSheet(): void {
  if (typeof window === 'undefined') return;

  try {
    localStorage.setItem(BOTTOM_SHEET_DISMISSED_KEY, Date.now().toString());
  } catch {
    // localStorage might be disabled
    console.warn('Failed to save bottom sheet dismissal state');
  }
}

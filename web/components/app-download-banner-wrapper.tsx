'use client';

import { SmartAppBanner } from './smart-app-banner';
import { AppDownloadBottomSheet } from './app-download-bottom-sheet';

/**
 * Wrapper component that coordinates the smart app banner and bottom sheet
 * - Banner: Persistent at top (dismissible for 7 days)
 * - Bottom sheet: Shows once per week on site entry (Reddit-style)
 */
export function AppDownloadBannerWrapper() {
  return (
    <>
      <SmartAppBanner />
      <AppDownloadBottomSheet />
    </>
  );
}

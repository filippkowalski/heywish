"use client";

import { useEffect, useState } from "react";
import { initializeAnalytics } from "@/lib/firebase";

const CONSENT_KEY = "jinnie-cookie-consent";
const CONSENT_TIMESTAMP_KEY = "jinnie-cookie-consent-timestamp";

/**
 * Detects if user is likely in EU based on timezone.
 * This is a client-side fallback. For production, consider using
 * server-side geo detection (e.g., Cloudflare CF-IPCountry header).
 */
function isLikelyEUUser(): boolean {
  try {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    const euTimezones = [
      "Europe/",
      "Atlantic/Reykjavik",
      "Atlantic/Faroe",
      "Atlantic/Canary",
    ];
    return euTimezones.some((tz) => timezone.startsWith(tz));
  } catch {
    // If timezone detection fails, assume EU for safety (require consent)
    return true;
  }
}

/**
 * Gets the current consent status from localStorage.
 */
function getConsentStatus(): "accepted" | "declined" | null {
  if (typeof window === "undefined") return null;

  const consent = localStorage.getItem(CONSENT_KEY);
  if (consent === "accepted" || consent === "declined") {
    return consent;
  }
  return null;
}

/**
 * Initializes Google Analytics consent mode based on region and user preference.
 * - Non-EU users: Default to granted, track immediately
 * - EU users without consent: Default to denied, send cookieless pings
 * - EU users with accepted consent: Grant full tracking
 */
export function AnalyticsProvider() {
  const [initialized, setInitialized] = useState(false);

  useEffect(() => {
    if (initialized || typeof window === "undefined") return;

    const isEU = isLikelyEUUser();
    const consent = getConsentStatus();

    // Initialize gtag if not already done
    if (!window.gtag) {
      const dataLayer = window.dataLayer || [];
      window.dataLayer = dataLayer;
      window.gtag = function gtag(...args: unknown[]) {
        dataLayer.push(args);
      };
    }

    if (!isEU) {
      // Non-EU users: Grant consent by default and initialize analytics
      window.gtag("consent", "update", {
        analytics_storage: "granted",
        ad_storage: "granted",
        ad_user_data: "granted",
        ad_personalization: "granted",
      });

      // Initialize Firebase Analytics immediately
      initializeAnalytics().then(() => {
        console.log("Analytics initialized for non-EU user");
      });
    } else {
      // EU users: Check if they previously gave consent
      if (consent === "accepted") {
        // Reapply granted consent for returning users
        window.gtag("consent", "update", {
          analytics_storage: "granted",
          ad_storage: "granted",
          ad_user_data: "granted",
          ad_personalization: "granted",
        });

        // Initialize Firebase Analytics
        initializeAnalytics().then(() => {
          console.log("Analytics initialized for returning EU user with consent");
        });
      } else if (consent === "declined") {
        // User explicitly declined, ensure it stays denied
        window.gtag("consent", "update", {
          analytics_storage: "denied",
          ad_storage: "denied",
          ad_user_data: "denied",
          ad_personalization: "denied",
        });
      }
      // If no consent yet, keep default 'denied' from layout.tsx
      // GA will still send cookieless pings in this state
    }

    setInitialized(true);
  }, [initialized]);

  return null;
}

/**
 * Handles consent acceptance (called from CookieConsent component).
 */
export function acceptConsent() {
  if (typeof window === "undefined") return;

  localStorage.setItem(CONSENT_KEY, "accepted");
  localStorage.setItem(CONSENT_TIMESTAMP_KEY, Date.now().toString());

  // Update consent mode
  if (window.gtag) {
    window.gtag("consent", "update", {
      analytics_storage: "granted",
      ad_storage: "granted",
      ad_user_data: "granted",
      ad_personalization: "granted",
    });
  }

  // Initialize Firebase Analytics
  initializeAnalytics().then(() => {
    console.log("Analytics initialized after consent acceptance");
  });
}

/**
 * Handles consent decline (called from CookieConsent component).
 */
export function declineConsent() {
  if (typeof window === "undefined") return;

  localStorage.setItem(CONSENT_KEY, "declined");
  localStorage.setItem(CONSENT_TIMESTAMP_KEY, Date.now().toString());

  // Ensure consent stays denied
  if (window.gtag) {
    window.gtag("consent", "update", {
      analytics_storage: "denied",
      ad_storage: "denied",
      ad_user_data: "denied",
      ad_personalization: "denied",
    });
  }
}

/**
 * Checks if user should see the consent banner.
 */
export function shouldShowConsentBanner(): boolean {
  if (typeof window === "undefined") return false;

  const isEU = isLikelyEUUser();
  const consent = getConsentStatus();

  // Only show to EU users who haven't made a choice
  return isEU && consent === null;
}

/**
 * Checks if user is from EU region.
 */
export function isEUUser(): boolean {
  return isLikelyEUUser();
}

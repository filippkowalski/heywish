"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { X } from "lucide-react";
import { initializeAnalytics } from "@/lib/firebase";

const CONSENT_KEY = "jinnie-cookie-consent";
const CONSENT_TIMESTAMP_KEY = "jinnie-cookie-consent-timestamp";
const CONSENT_EXPIRY_DAYS = 365;

export function CookieConsent() {
  const [showBanner, setShowBanner] = useState(false);

  useEffect(() => {
    // Check if consent was already given
    const consent = localStorage.getItem(CONSENT_KEY);
    const consentTimestamp = localStorage.getItem(CONSENT_TIMESTAMP_KEY);

    // Check if consent has expired (after 1 year)
    if (consent && consentTimestamp) {
      const consentDate = new Date(parseInt(consentTimestamp));
      const expiryDate = new Date(consentDate);
      expiryDate.setDate(expiryDate.getDate() + CONSENT_EXPIRY_DAYS);

      if (new Date() > expiryDate) {
        // Consent expired, show banner again
        localStorage.removeItem(CONSENT_KEY);
        localStorage.removeItem(CONSENT_TIMESTAMP_KEY);
      }
    }

    // Detect if user is likely in EU based on timezone
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    const euTimezones = [
      "Europe/",
      "Atlantic/Reykjavik",
      "Atlantic/Faroe",
      "Atlantic/Canary",
    ];
    const isLikelyEU = euTimezones.some((tz) => timezone.startsWith(tz));

    // Show banner if no consent given and user is likely in EU
    if (!consent) {
      // Show to everyone for GDPR safety, or only EU users
      setShowBanner(isLikelyEU);
    } else if (consent === "accepted") {
      // Initialize analytics if consent was previously given
      initializeAnalytics();
    }
  }, []);

  const handleAccept = () => {
    localStorage.setItem(CONSENT_KEY, "accepted");
    localStorage.setItem(CONSENT_TIMESTAMP_KEY, Date.now().toString());
    setShowBanner(false);

    // Initialize analytics
    initializeAnalytics();

    // Load Google Analytics
    if (typeof window !== "undefined" && window.gtag) {
      window.gtag("consent", "update", {
        analytics_storage: "granted",
      });
    }
  };

  const handleDecline = () => {
    localStorage.setItem(CONSENT_KEY, "declined");
    localStorage.setItem(CONSENT_TIMESTAMP_KEY, Date.now().toString());
    setShowBanner(false);

    // Deny analytics
    if (typeof window !== "undefined" && window.gtag) {
      window.gtag("consent", "update", {
        analytics_storage: "denied",
      });
    }
  };

  if (!showBanner) {
    return null;
  }

  return (
    <div className="fixed bottom-4 left-4 right-4 z-50 sm:left-auto sm:right-4 sm:max-w-md">
      <div className="rounded-lg border bg-background/95 p-4 shadow-lg backdrop-blur supports-[backdrop-filter]:bg-background/80">
        <div className="flex items-start gap-3">
          <div className="flex-1 space-y-2">
            <p className="text-sm leading-relaxed text-foreground">
              We use cookies and analytics to improve your experience. We also use affiliate tracking cookies when you click product links—we may earn a commission at no extra cost to you.
            </p>
            <p className="text-xs text-muted-foreground">
              See our{" "}
              <Link href="/privacy" className="underline hover:text-foreground">
                Privacy Policy
              </Link>
              {" "}and{" "}
              <Link href="/affiliate-disclosure" className="underline hover:text-foreground">
                Affiliate Disclosure
              </Link>
              {" "}for details.
            </p>
            <div className="flex gap-2">
              <Button
                size="sm"
                onClick={handleAccept}
                className="h-8 px-3 text-xs"
              >
                Accept
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={handleDecline}
                className="h-8 px-3 text-xs"
              >
                Decline
              </Button>
            </div>
          </div>
          <button
            onClick={handleDecline}
            className="text-muted-foreground hover:text-foreground transition-colors"
            aria-label="Close"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>
  );
}

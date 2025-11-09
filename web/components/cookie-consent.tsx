"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { X } from "lucide-react";
import { acceptConsent, declineConsent, shouldShowConsentBanner } from "@/components/analytics-provider";

export function CookieConsent() {
  const [showBanner, setShowBanner] = useState(false);

  useEffect(() => {
    // Determine if we should show the banner
    // (EU users who haven't made a choice)
    setShowBanner(shouldShowConsentBanner());
  }, []);

  const handleAccept = () => {
    acceptConsent();
    setShowBanner(false);
  };

  const handleDecline = () => {
    declineConsent();
    setShowBanner(false);
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

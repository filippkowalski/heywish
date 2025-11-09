"use client";

import { useEffect, useRef, Suspense } from "react";
import { usePathname, useSearchParams } from "next/navigation";
import { analytics } from "@/lib/firebase";
import { logEvent } from "firebase/analytics";

const GA_MEASUREMENT_ID = "G-BRDJHGM96Y";

/**
 * PageViewTracker monitors route changes in the Next.js app and sends
 * page_view events to both Google Analytics and Firebase Analytics.
 *
 * This ensures that SPA navigations are tracked, not just initial page loads.
 */
function PageViewTrackerInner() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const initialLoadRef = useRef(true);

  useEffect(() => {
    // Skip the initial load since layout.tsx already tracks it
    if (initialLoadRef.current) {
      initialLoadRef.current = false;
      return;
    }

    // Construct the full URL path including search params
    const url = searchParams?.toString()
      ? `${pathname}?${searchParams.toString()}`
      : pathname;

    // Send page_view to Google Analytics
    if (typeof window !== "undefined" && window.gtag) {
      window.gtag("config", GA_MEASUREMENT_ID, {
        page_path: url,
      });

      // Also send an explicit page_view event
      window.gtag("event", "page_view", {
        page_path: url,
        page_location: window.location.href,
        page_title: document.title,
      });
    }

    // Send page_view to Firebase Analytics (if initialized)
    if (analytics) {
      logEvent(analytics, "page_view", {
        page_path: url,
        page_location: window.location.href,
        page_title: document.title,
      });
    }

    console.log("Page view tracked:", url);
  }, [pathname, searchParams]);

  return null;
}

/**
 * Wrapper component with Suspense boundary for PageViewTrackerInner.
 */
export function PageViewTracker() {
  return (
    <Suspense fallback={null}>
      <PageViewTrackerInner />
    </Suspense>
  );
}

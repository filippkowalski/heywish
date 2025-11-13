/**
 * Build version for cache busting.
 * Update this when you need to force all users to reload.
 */
export const APP_VERSION = "1.0.0";

/**
 * Checks if user has the latest version.
 * Can be used to prompt users to refresh on critical updates.
 */
export function checkVersion() {
  if (typeof window === "undefined") return;

  const storedVersion = localStorage.getItem("app-version");

  if (storedVersion !== APP_VERSION) {
    console.log(`Version changed: ${storedVersion} → ${APP_VERSION}`);
    localStorage.setItem("app-version", APP_VERSION);

    // Optionally: Force reload on version change
    // window.location.reload();
  }
}

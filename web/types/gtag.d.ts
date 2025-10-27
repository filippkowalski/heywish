export {};

declare global {
  interface Window {
    gtag?: (
      command: "config" | "set" | "event" | "consent",
      targetId: string | "update",
      config?: Record<string, unknown>
    ) => void;
    dataLayer?: unknown[];
  }
}

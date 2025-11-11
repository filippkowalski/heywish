import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Disable image optimization for Cloudflare Pages
  images: {
    unoptimized: true,
  },

  // Strict mode for better development experience
  reactStrictMode: true,

  // Environment variables that should be available on the client
  env: {
    NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL,
  },
};

export default nextConfig;

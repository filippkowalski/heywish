"use client";

import Link from "next/link";
import { GlobalSearch } from "./global-search";

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto flex h-14 items-center gap-4 px-4 md:px-6">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2 flex-shrink-0">
          <span className="text-xl font-semibold font-poppins">Jinnie.co</span>
        </Link>

        {/* Search */}
        <div className="flex-1 max-w-md">
          <GlobalSearch />
        </div>
      </div>
    </header>
  );
}

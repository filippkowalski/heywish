"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Search, User, Loader2 } from "lucide-react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

interface SearchUser {
  id: string;
  username: string;
  fullName?: string | null;
  avatarUrl?: string | null;
  bio?: string | null;
  publicWishlistCount: number;
}

interface SearchResponse {
  users: SearchUser[];
}

export function GlobalSearch() {
  const [isOpen, setIsOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<SearchUser[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const router = useRouter();

  // Debounced search
  useEffect(() => {
    if (query.trim().length < 2) {
      setResults([]);
      return;
    }

    setIsLoading(true);
    const timeoutId = setTimeout(async () => {
      try {
        const API_BASE_URL =
          process.env.NEXT_PUBLIC_API_BASE_URL ||
          "https://openai-rewrite.onrender.com/jinnie/v1";
        const response = await fetch(
          `${API_BASE_URL}/public/users?search=${encodeURIComponent(query)}&limit=10`
        );

        if (response.ok) {
          const data: SearchResponse = await response.json();
          setResults(data.users || []);
          setSelectedIndex(0);
        }
      } catch (error) {
        console.error("Search error:", error);
        setResults([]);
      } finally {
        setIsLoading(false);
      }
    }, 300);

    return () => clearTimeout(timeoutId);
  }, [query]);

  // Handle keyboard navigation
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!isOpen) return;

      switch (e.key) {
        case "ArrowDown":
          e.preventDefault();
          setSelectedIndex((prev) => Math.min(prev + 1, results.length - 1));
          break;
        case "ArrowUp":
          e.preventDefault();
          setSelectedIndex((prev) => Math.max(prev - 1, 0));
          break;
        case "Enter":
          e.preventDefault();
          if (results[selectedIndex]) {
            router.push(`/${results[selectedIndex].username}`);
            handleClose();
          }
          break;
        case "Escape":
          handleClose();
          break;
      }
    };

    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, results, selectedIndex, router]);

  const handleClose = useCallback(() => {
    setIsOpen(false);
    setQuery("");
    setResults([]);
    inputRef.current?.blur();
  }, []);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(e.target as Node) &&
        inputRef.current &&
        !inputRef.current.contains(e.target as Node)
      ) {
        handleClose();
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [handleClose]);

  return (
    <div className="relative w-full">
      <div className="relative">
        <Search className="absolute left-2 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground md:left-3" />
        <Input
          ref={inputRef}
          type="text"
          placeholder="Search users..."
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setIsOpen(true);
          }}
          onFocus={() => setIsOpen(true)}
          className="pl-8 pr-8 text-sm md:pl-9 md:pr-9 md:text-base h-9"
        />
        {isLoading && (
          <Loader2 className="absolute right-2 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-muted-foreground md:right-3" />
        )}
      </div>

      {/* Dropdown Results */}
      {isOpen && query.trim().length >= 2 && (
        <div
          ref={dropdownRef}
          className="absolute left-0 right-0 top-full z-50 mt-2 overflow-hidden rounded-lg border border-border bg-card shadow-lg md:left-auto md:right-auto md:w-full"
        >
          {results.length > 0 ? (
            <div className="max-h-[60vh] overflow-y-auto md:max-h-80">
              {results.map((user, index) => (
                <Link
                  key={user.id}
                  href={`/${user.username}`}
                  onClick={handleClose}
                  className={cn(
                    "flex items-center gap-2 px-3 py-2.5 transition-colors hover:bg-accent md:gap-3 md:px-4 md:py-3",
                    index === selectedIndex && "bg-accent"
                  )}
                >
                  <Avatar className="h-9 w-9 rounded-lg border border-border flex-shrink-0 md:h-10 md:w-10">
                    {user.avatarUrl ? (
                      <AvatarImage src={user.avatarUrl} alt={user.username} />
                    ) : null}
                    <AvatarFallback className="rounded-lg">
                      <User className="h-4 w-4 md:h-5 md:w-5" />
                    </AvatarFallback>
                  </Avatar>
                  <div className="min-w-0 flex-1 overflow-hidden">
                    <div className="flex items-center gap-1.5 md:gap-2">
                      <p className="truncate font-medium text-sm">
                        @{user.username}
                      </p>
                      {user.publicWishlistCount > 0 && (
                        <span className="text-xs text-muted-foreground whitespace-nowrap flex-shrink-0">
                          {user.publicWishlistCount}{" "}
                          {user.publicWishlistCount === 1 ? "list" : "lists"}
                        </span>
                      )}
                    </div>
                    {user.fullName && (
                      <p className="truncate text-xs text-muted-foreground">
                        {user.fullName}
                      </p>
                    )}
                  </div>
                </Link>
              ))}
            </div>
          ) : (
            <div className="px-3 py-4 text-center text-sm text-muted-foreground md:px-4 md:py-6">
              {isLoading ? "Searching..." : "No users found"}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

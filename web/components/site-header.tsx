"use client";

import { useState } from "react";
import Link from "next/link";
import { useAuth } from "@/lib/auth/AuthContext.client";
import { GlobalSearch } from "./global-search";
import { Button } from "./ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "./ui/avatar";
import { SignInModal } from "./auth/SignInModal.client";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "./ui/dropdown-menu";
import { ListPlus, LogOut, Loader2, Settings } from "lucide-react";
import { toast } from "sonner";
import { usePathname } from "next/navigation";

export function SiteHeader() {
  const { user, backendUser, loading, signOut, isReservationSession } = useAuth();
  const [showSignIn, setShowSignIn] = useState(false);
  const [isSigningOut, setIsSigningOut] = useState(false);
  const pathname = usePathname();

  const handleSignOut = async () => {
    setIsSigningOut(true);
    try {
      await signOut();
      toast.success("Signed out successfully");
    } catch {
      toast.error("Failed to sign out");
    } finally {
      setIsSigningOut(false);
    }
  };

  const getUserInitials = (name?: string | null, email?: string | null) => {
    if (name) {
      return name
        .split(" ")
        .map((n) => n[0])
        .join("")
        .toUpperCase()
        .slice(0, 2);
    }
    if (email) {
      return email[0].toUpperCase();
    }
    return "U";
  };

  // Get profile URL - use username if available, otherwise fallback
  const profileUrl = backendUser?.username ? `/${backendUser.username}` : "/";

  // Check if user is viewing their own profile
  const isOnOwnProfile = backendUser?.username && pathname === `/${backendUser.username}`;

  // Check if user has completed onboarding
  const hasUsername = !!backendUser?.username;

  const handleManageWishlists = () => {
    // Dispatch custom event that ProfileOwnershipWrapper will listen to
    window.dispatchEvent(new CustomEvent('openManageWishlists'));
  };

  return (
    <>
      <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto flex h-14 items-center gap-2 px-3 md:gap-4 md:px-6">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 flex-shrink-0">
            <span className="text-lg font-semibold font-poppins md:text-xl">Jinnie.co</span>
          </Link>

          {/* Search */}
          <div className="flex-1 min-w-0 md:max-w-md">
            <GlobalSearch />
          </div>

          {/* Spacer to push auth section to the right - only on desktop */}
          <div className="hidden md:block md:flex-1" />

          {/* Auth Section - aligned to the right */}
          <div className="flex items-center gap-1 flex-shrink-0 md:gap-2">
            {/* Browse Link - always visible */}
            <Button asChild variant="ghost" size="sm">
              <Link href="/browse">Browse</Link>
            </Button>

            {/* Gift Guides Link - always visible */}
            <Button asChild variant="ghost" size="sm">
              <Link href="/gift-guides">Guides</Link>
            </Button>

            {/* Inspo Link - always visible */}
            <Button asChild variant="ghost" size="sm">
              <Link href="/inspo">Inspo</Link>
            </Button>

            {loading ? (
              <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
            ) : user && !isReservationSession ? (
              <>
                {hasUsername && (
                  <Button asChild variant="ghost" size="sm" className="hidden md:flex">
                    <Link href={profileUrl}>
                      <ListPlus className="mr-2 h-4 w-4" />
                      My Wishlists
                    </Link>
                  </Button>
                )}

                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" className="relative h-8 w-8 rounded-full">
                      <Avatar className="h-8 w-8">
                        <AvatarImage
                          src={backendUser?.avatar_url || user?.photoURL || undefined}
                          alt={backendUser?.full_name || user?.displayName || ""}
                        />
                        <AvatarFallback>
                          {getUserInitials(backendUser?.full_name || user?.displayName, backendUser?.email || user?.email)}
                        </AvatarFallback>
                      </Avatar>
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent className="w-56" align="end" forceMount>
                    <DropdownMenuLabel className="font-normal">
                      <div className="flex flex-col space-y-1">
                        <p className="text-sm font-medium leading-none">
                          {backendUser?.full_name || user?.displayName || "User"}
                        </p>
                        {backendUser?.username && (
                          <p className="text-xs leading-none text-muted-foreground">@{backendUser.username}</p>
                        )}
                        <p className="text-xs leading-none text-muted-foreground">
                          {backendUser?.email || user?.email}
                        </p>
                      </div>
                    </DropdownMenuLabel>
                    <DropdownMenuSeparator />
                    {hasUsername && (
                      <DropdownMenuItem asChild>
                        <Link href={profileUrl} className="cursor-pointer">
                          <ListPlus className="mr-2 h-4 w-4" />
                          My Wishlists
                        </Link>
                      </DropdownMenuItem>
                    )}
                    {isOnOwnProfile && (
                      <DropdownMenuItem onClick={handleManageWishlists} className="cursor-pointer">
                        <Settings className="mr-2 h-4 w-4" />
                        Manage Wishlists
                      </DropdownMenuItem>
                    )}
                    {hasUsername && (
                      <DropdownMenuItem asChild>
                        <Link href="/settings" className="cursor-pointer">
                          <Settings className="mr-2 h-4 w-4" />
                          Settings
                        </Link>
                      </DropdownMenuItem>
                    )}
                    <DropdownMenuSeparator />
                    <DropdownMenuItem onClick={handleSignOut} disabled={isSigningOut} className="cursor-pointer">
                      {isSigningOut ? (
                        <>
                          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                          Signing out...
                        </>
                      ) : (
                        <>
                          <LogOut className="mr-2 h-4 w-4" />
                          Sign out
                        </>
                      )}
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </>
            ) : (
              <Button onClick={() => setShowSignIn(true)} size="sm">
                Sign In
              </Button>
            )}
          </div>
        </div>
      </header>

      <SignInModal open={showSignIn} onOpenChange={setShowSignIn} />
    </>
  );
}

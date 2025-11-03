"use client";

import { useState } from "react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Gift, Heart, MapPin } from "lucide-react";
import { FollowButton } from "@/components/follow-button.client";
import { FollowDialog } from "@/components/follow-dialog.client";

interface ProfileHeaderProps {
  username: string;
  userId: string;
  isOwnProfile: boolean;
  avatarUrl?: string | null;
  bio?: string | null;
  location?: string | null;
  wishlistCount: number;
  wishCount: number;
}

const formatNumber = (value: number) =>
  new Intl.NumberFormat("en-US", {
    notation: value >= 1000 ? "compact" : "standard",
    maximumFractionDigits: value >= 1000 ? 1 : 0,
  }).format(value);

export function ProfileHeader({
  username,
  userId,
  isOwnProfile,
  avatarUrl,
  bio,
  location,
  wishlistCount,
  wishCount,
}: ProfileHeaderProps) {
  const [showFollowDialog, setShowFollowDialog] = useState(false);

  return (
    <>
      <div className="flex items-start gap-3 sm:gap-4">
        <Avatar className="h-20 w-20 sm:h-24 sm:w-24 rounded-xl border border-border flex-shrink-0">
          {avatarUrl ? (
            <AvatarImage src={avatarUrl} alt={`@${username}`} />
          ) : null}
          <AvatarFallback className="rounded-xl text-lg sm:text-xl font-semibold">
            {username.slice(0, 2).toUpperCase()}
          </AvatarFallback>
        </Avatar>
        <div className="min-w-0 flex-1 space-y-2.5 sm:space-y-3">
          <div className="flex items-start justify-between gap-2">
            <div className="space-y-1.5 sm:space-y-2 min-w-0 flex-1">
              <h1 className="truncate text-xl font-semibold sm:text-2xl md:text-3xl">
                @{username}
              </h1>
              {location ? (
                <p className="flex items-center gap-1 text-xs text-muted-foreground sm:text-sm">
                  <MapPin className="h-3 w-3 sm:h-3.5 sm:w-3.5" />
                  <span className="truncate">{location}</span>
                </p>
              ) : null}
            </div>

            {/* Follow Button - only show if not own profile */}
            <div className="flex-shrink-0">
              <FollowButton
                username={username}
                userId={userId}
                isOwnProfile={isOwnProfile}
                onFollowClick={() => setShowFollowDialog(true)}
              />
            </div>
          </div>

          {/* Bio */}
          {bio ? (
            <p className="text-sm sm:text-base text-muted-foreground leading-relaxed">
              {bio}
            </p>
          ) : null}

          {/* Stats */}
          <div className="flex flex-wrap gap-x-4 gap-y-2 text-xs sm:text-sm text-muted-foreground">
            <span className="inline-flex items-center gap-1.5 sm:gap-2">
              <Gift className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-primary flex-shrink-0" />
              <span className="font-medium text-foreground">{wishlistCount}</span> wishlists
            </span>
            <span className="inline-flex items-center gap-1.5 sm:gap-2">
              <Heart className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-rose-500 flex-shrink-0" />
              <span className="font-medium text-foreground">{formatNumber(wishCount)}</span> wishes
            </span>
          </div>
        </div>
      </div>

      {/* Follow Dialog */}
      <FollowDialog
        open={showFollowDialog}
        onOpenChange={setShowFollowDialog}
        username={username}
        avatarUrl={avatarUrl}
      />
    </>
  );
}

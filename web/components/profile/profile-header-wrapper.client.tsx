'use client';

import { useState } from 'react';
import { ProfileHeader } from './profile-header.client';
import { useOwnership } from './ProfileOwnershipWrapper.client';
import { FollowButton } from '@/components/follow-button.client';
import { FollowDialog } from '@/components/follow-dialog.client';

interface ProfileHeaderWrapperProps {
  userId: string;
  username: string;
  avatarUrl?: string | null;
  bio?: string | null;
  location?: string | null;
  wishlistCount: number;
  wishCount: number;
}

/**
 * Wrapper component that connects ProfileHeader to the ownership context
 * This allows us to determine if the user is viewing their own profile
 */
export function ProfileHeaderWrapper(props: ProfileHeaderWrapperProps) {
  const ownership = useOwnership();
  const isOwnProfile = ownership?.isOwner ?? false;
  const [showFollowDialog, setShowFollowDialog] = useState(false);

  return (
    <>
      <header className="border-b bg-card/50">
        <div className="container mx-auto px-4 py-6 sm:py-8 md:py-10 md:px-6">
          <ProfileHeader
            username={props.username}
            avatarUrl={props.avatarUrl}
            bio={props.bio}
            location={props.location}
            wishlistCount={props.wishlistCount}
            wishCount={props.wishCount}
          />
        </div>
      </header>

      {/* Follow Button Section - Below header, above wishlists */}
      {!isOwnProfile ? (
        <div className="border-b bg-background">
          <div className="container mx-auto px-4 py-4 md:px-6">
            <FollowButton
              username={props.username}
              userId={props.userId}
              isOwnProfile={isOwnProfile}
              onFollowClick={() => setShowFollowDialog(true)}
            />
          </div>
        </div>
      ) : null}

      {/* Follow Dialog */}
      <FollowDialog
        open={showFollowDialog}
        onOpenChange={setShowFollowDialog}
        username={props.username}
        avatarUrl={props.avatarUrl}
      />
    </>
  );
}

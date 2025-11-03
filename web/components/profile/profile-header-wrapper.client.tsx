'use client';

import { ProfileHeader } from './profile-header.client';
import { useOwnership } from './ProfileOwnershipWrapper.client';

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

  return (
    <header className="border-b bg-card/50">
      <div className="container mx-auto px-4 py-6 sm:py-8 md:py-10 md:px-6">
        <ProfileHeader
          {...props}
          isOwnProfile={isOwnProfile}
        />
      </div>
    </header>
  );
}

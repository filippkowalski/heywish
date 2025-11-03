'use client';

interface FollowButtonProps {
  username: string;
  userId: string;
  isOwnProfile: boolean;
  className?: string;
  onFollowClick?: () => void;
}

/**
 * Follow button component for user profiles
 *
 * Shows:
 * - Hidden if viewing own profile
 * - "Follow @username" for all other cases (authenticated or not)
 *
 * Clicking the button triggers a dialog to download the mobile app
 * and opens a deep link to the user's profile in the app
 */
export function FollowButton({
  username,
  isOwnProfile,
  className = '',
  onFollowClick,
}: FollowButtonProps) {
  // Hide button if viewing own profile
  if (isOwnProfile) {
    return null;
  }

  const handleClick = () => {
    if (onFollowClick) {
      onFollowClick();
    }
  };

  return (
    <button
      onClick={handleClick}
      className={`
        inline-flex items-center justify-center
        px-6 py-2.5
        bg-black text-white
        rounded-lg
        font-medium text-sm
        transition-all duration-200
        hover:bg-gray-800
        active:scale-95
        disabled:opacity-50 disabled:cursor-not-allowed
        ${className}
      `}
    >
      <svg
        className="w-4 h-4 mr-2"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M12 4v16m8-8H4"
        />
      </svg>
      Follow @{username}
    </button>
  );
}

'use client';

import { Button } from '@/components/ui/button';
import { validateUsername } from '@/lib/onboarding/constants';
import { useOnboarding } from '@/lib/onboarding/OnboardingContext.client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth/AuthContext.client';

export function UsernameStep() {
  const { data, updateData, setStep, usernameCheck, checkUsernameAvailability, completeOnboarding, isSubmitting } = useOnboarding();
  const { user } = useAuth();
  const [username, setUsername] = useState(data.username || '');
  const [localError, setLocalError] = useState<string | null>(null);

  // Pre-fill from email if available (only on initial mount)
  useEffect(() => {
    if (!username && !data.username && user?.email) {
      // Skip autopopulation for Apple Private Relay emails (align with mobile behavior)
      if (user.email.includes('@privaterelay.appleid.com')) {
        return;
      }

      const emailPrefix = user.email.split('@')[0].toLowerCase().replace(/[^a-z0-9._]/g, '');
      if (emailPrefix.length >= 3) {
        setUsername(emailPrefix);
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Check availability when username changes
  useEffect(() => {
    const error = validateUsername(username);
    setLocalError(error);

    if (!error && username) {
      checkUsernameAvailability(username);
    }
  }, [username, checkUsernameAvailability]);

  const handleUsernameChange = (value: string) => {
    // Auto-convert to lowercase and filter out invalid characters
    // Only allow: lowercase letters, numbers, dots, underscores (align with mobile behavior)
    const filtered = value.toLowerCase().replace(/[^a-z0-9._]/g, '');
    setUsername(filtered);
    updateData('username', filtered);
  };

  const handleContinue = async () => {
    if (!canContinue) return;

    const success = await completeOnboarding();
    if (success) {
      setStep('complete');
    }
  };

  const handleBack = () => {
    setStep('profile');
  };

  // Determine if user can continue
  const canContinue =
    username.length >= 3 &&
    !localError &&
    usernameCheck.available &&
    !usernameCheck.checking &&
    !isSubmitting;

  // Status indicator
  const getStatusIndicator = () => {
    if (!username) return null;
    if (localError) {
      return (
        <div className="flex items-center gap-2 text-sm text-red-600">
          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
          </svg>
          <span>{localError}</span>
        </div>
      );
    }
    if (usernameCheck.checking) {
      return (
        <div className="flex items-center gap-2 text-sm text-gray-600">
          <div className="w-4 h-4 border-2 border-gray-300 border-t-gray-600 rounded-full animate-spin" />
          <span>Checking availability...</span>
        </div>
      );
    }
    if (usernameCheck.available) {
      return (
        <div className="flex items-center gap-2 text-sm text-green-600">
          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
          </svg>
          <span>Available!</span>
        </div>
      );
    }
    if (!usernameCheck.available && username.length >= 3) {
      return (
        <div className="space-y-2">
          <div className="flex items-center gap-2 text-sm text-red-600">
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
            </svg>
            <span>Username is already taken</span>
          </div>
          {usernameCheck.suggestions && usernameCheck.suggestions.length > 0 && (
            <div className="pl-6">
              <p className="text-xs text-gray-600 mb-2">Try these:</p>
              <div className="flex flex-wrap gap-2">
                {usernameCheck.suggestions.map((suggestion) => (
                  <button
                    key={suggestion}
                    onClick={() => handleUsernameChange(suggestion)}
                    className="px-3 py-1 text-xs bg-gray-100 hover:bg-gray-200 rounded-full transition-colors"
                  >
                    {suggestion}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      );
    }
    return null;
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen p-6 bg-gradient-to-b from-white to-gray-50">
      <div className="w-full max-w-md space-y-8">
        {/* Header */}
        <div className="text-center space-y-3">
          <h1 className="text-4xl font-bold tracking-tight">Choose your username</h1>
          <p className="text-lg text-gray-600">
            This is how others will find you on Jinnie
          </p>
        </div>

        {/* Form */}
        <div className="space-y-4">
          <div className="space-y-3">
            <div className="relative">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 text-lg">
                @
              </span>
              <input
                type="text"
                value={username}
                onChange={(e) => handleUsernameChange(e.target.value)}
                placeholder="yourname"
                className="w-full h-14 pl-10 pr-4 text-base border-2 border-gray-200 rounded-xl focus:border-black focus:outline-none transition-colors"
                maxLength={30}
                autoFocus
              />
            </div>

            {/* Status indicator */}
            <div className="min-h-[24px]">
              {getStatusIndicator()}
            </div>

            {/* Profile URL preview */}
            {username && !localError && (
              <div className="text-sm text-gray-500">
                jinnie.co/<span className="font-medium text-gray-700">{username}</span>
              </div>
            )}
          </div>

          {/* Guidelines */}
          <div className="bg-gray-50 rounded-xl p-4 space-y-2">
            <p className="text-sm font-medium text-gray-700">Username guidelines:</p>
            <ul className="text-xs text-gray-600 space-y-1 pl-4">
              <li>• 3-30 characters</li>
              <li>• Lowercase letters, numbers, periods, and underscores only</li>
              <li>• Cannot start or end with a period</li>
              <li>• No consecutive periods</li>
            </ul>
          </div>
        </div>

        {/* Actions */}
        <div className="flex gap-4 pt-4">
          <Button
            onClick={handleBack}
            variant="outline"
            className="flex-1 h-14 text-base"
            disabled={isSubmitting}
          >
            Back
          </Button>
          <Button
            onClick={handleContinue}
            disabled={!canContinue}
            className="flex-1 h-14 text-base bg-black hover:bg-gray-800 disabled:bg-gray-200 disabled:text-gray-400"
          >
            {isSubmitting ? (
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                <span>Creating profile...</span>
              </div>
            ) : (
              'Complete'
            )}
          </Button>
        </div>

        {/* Progress indicator */}
        <div className="flex justify-center gap-2 pt-4">
          <div className="w-2 h-2 rounded-full bg-black" />
          <div className="w-2 h-2 rounded-full bg-black" />
          <div className="w-2 h-2 rounded-full bg-black" />
          <div className="w-2 h-2 rounded-full bg-gray-300" />
        </div>
      </div>
    </div>
  );
}

'use client';

import { Button } from '@/components/ui/button';
import { GENDER_OPTIONS } from '@/lib/onboarding/constants';
import { useOnboarding } from '@/lib/onboarding/OnboardingContext.client';
import { useState } from 'react';

export function ProfileDetailsStep() {
  const { data, updateData, setStep } = useOnboarding();
  const [birthdate, setBirthdate] = useState(data.birthdate || '');
  const [gender, setGender] = useState(data.gender || '');

  const canContinue = birthdate && gender;

  const handleContinue = () => {
    updateData('birthdate', birthdate);
    updateData('gender', gender);
    setStep('username');
  };

  const handleBack = () => {
    setStep('interests');
  };

  // Calculate date range
  const today = new Date();
  const maxDate = today.toISOString().split('T')[0]; // Today's date

  // Calculate min date (120 years ago)
  const minDate = new Date(today.getFullYear() - 120, today.getMonth(), today.getDate())
    .toISOString()
    .split('T')[0];

  return (
    <div className="flex flex-col items-center justify-center min-h-screen p-6 bg-gradient-to-b from-white to-gray-50">
      <div className="w-full max-w-md space-y-8">
        {/* Header */}
        <div className="text-center space-y-3">
          <h1 className="text-4xl font-bold tracking-tight">Tell us about yourself</h1>
          <p className="text-lg text-gray-600">
            This helps us personalize your experience
          </p>
        </div>

        {/* Form */}
        <div className="space-y-6">
          {/* Birthday */}
          <div className="space-y-2">
            <label htmlFor="birthdate" className="block text-sm font-medium text-gray-700">
              Birthday
            </label>
            <input
              id="birthdate"
              type="date"
              value={birthdate}
              onChange={(e) => setBirthdate(e.target.value)}
              min={minDate}
              max={maxDate}
              className="w-full h-14 px-4 text-base border-2 border-gray-200 rounded-xl focus:border-black focus:outline-none transition-colors"
            />
          </div>

          {/* Gender */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">
              Gender
            </label>
            <div className="grid grid-cols-2 gap-3">
              {GENDER_OPTIONS.map((option) => {
                const isSelected = gender === option.value;
                return (
                  <button
                    key={option.value}
                    onClick={() => setGender(option.value)}
                    className={`
                      flex items-center justify-center h-14 px-4 rounded-xl border-2 text-base font-medium transition-all
                      ${
                        isSelected
                          ? 'border-black bg-black text-white'
                          : 'border-gray-200 bg-white hover:border-gray-300'
                      }
                    `}
                  >
                    {option.label}
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex gap-4 pt-4">
          <Button
            onClick={handleBack}
            variant="outline"
            className="flex-1 h-14 text-base"
          >
            Back
          </Button>
          <Button
            onClick={handleContinue}
            disabled={!canContinue}
            className="flex-1 h-14 text-base bg-black hover:bg-gray-800 disabled:bg-gray-200 disabled:text-gray-400"
          >
            Continue
          </Button>
        </div>

        {/* Progress indicator */}
        <div className="flex justify-center gap-2 pt-4">
          <div className="w-2 h-2 rounded-full bg-black" />
          <div className="w-2 h-2 rounded-full bg-black" />
          <div className="w-2 h-2 rounded-full bg-gray-300" />
          <div className="w-2 h-2 rounded-full bg-gray-300" />
        </div>
      </div>
    </div>
  );
}

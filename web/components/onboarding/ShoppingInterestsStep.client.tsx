'use client';

import { Button } from '@/components/ui/button';
import { SHOPPING_CATEGORIES } from '@/lib/onboarding/constants';
import { useOnboarding } from '@/lib/onboarding/OnboardingContext.client';
import { useState } from 'react';

export function ShoppingInterestsStep() {
  const { data, updateData, setStep } = useOnboarding();
  const [selectedInterests, setSelectedInterests] = useState<string[]>(
    data.shopping_interests || []
  );

  const toggleInterest = (id: string) => {
    setSelectedInterests((prev) =>
      prev.includes(id) ? prev.filter((i) => i !== id) : [...prev, id]
    );
  };

  const handleContinue = () => {
    updateData('shopping_interests', selectedInterests);
    setStep('profile');
  };

  const handleSkip = () => {
    updateData('shopping_interests', []);
    setStep('profile');
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen p-6 bg-gradient-to-b from-white to-gray-50">
      <div className="w-full max-w-2xl space-y-8">
        {/* Header */}
        <div className="text-center space-y-3">
          <h1 className="text-4xl font-bold tracking-tight">What do you love to shop for?</h1>
          <p className="text-lg text-gray-600">
            Select your interests to get personalized recommendations
          </p>
        </div>

        {/* Categories Grid */}
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          {SHOPPING_CATEGORIES.map((category) => {
            const isSelected = selectedInterests.includes(category.id);
            return (
              <button
                key={category.id}
                onClick={() => toggleInterest(category.id)}
                className={`
                  flex flex-col items-center gap-3 p-6 rounded-2xl border-2 transition-all
                  ${
                    isSelected
                      ? 'border-black bg-black text-white shadow-lg scale-105'
                      : 'border-gray-200 bg-white hover:border-gray-300 hover:shadow-md'
                  }
                `}
                style={{
                  backgroundColor: isSelected ? category.color : undefined,
                  borderColor: isSelected ? category.color : undefined,
                }}
              >
                <span className="text-4xl">{category.emoji}</span>
                <span className="font-medium text-sm text-center">{category.label}</span>
              </button>
            );
          })}
        </div>

        {/* Selected Count */}
        {selectedInterests.length > 0 && (
          <p className="text-center text-sm text-gray-600">
            {selectedInterests.length} {selectedInterests.length === 1 ? 'interest' : 'interests'}{' '}
            selected
          </p>
        )}

        {/* Actions */}
        <div className="flex gap-4">
          <Button
            onClick={handleSkip}
            variant="outline"
            className="flex-1 h-14 text-base"
          >
            Skip for now
          </Button>
          <Button
            onClick={handleContinue}
            disabled={selectedInterests.length === 0}
            className="flex-1 h-14 text-base bg-black hover:bg-gray-800"
          >
            Continue
          </Button>
        </div>
      </div>
    </div>
  );
}

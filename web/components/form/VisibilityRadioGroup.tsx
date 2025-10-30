'use client';

import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Label } from '@/components/ui/label';
import { Eye, Users, Lock } from 'lucide-react';
import { cn } from '@/lib/utils';

interface VisibilityOption {
  value: 'public' | 'friends' | 'private';
  label: string;
  description: string;
  icon: React.ReactNode;
}

const visibilityOptions: VisibilityOption[] = [
  {
    value: 'public',
    label: 'Public',
    description: 'Anyone can view this wishlist',
    icon: <Eye className="h-5 w-5" />,
  },
  {
    value: 'friends',
    label: 'Friends',
    description: 'Only your friends can view',
    icon: <Users className="h-5 w-5" />,
  },
  {
    value: 'private',
    label: 'Private',
    description: 'Only you can view',
    icon: <Lock className="h-5 w-5" />,
  },
];

interface VisibilityRadioGroupProps {
  value: string;
  onValueChange: (value: string) => void;
  disabled?: boolean;
}

export function VisibilityRadioGroup({ value, onValueChange, disabled }: VisibilityRadioGroupProps) {
  return (
    <RadioGroup value={value} onValueChange={onValueChange} disabled={disabled} className="gap-3">
      {visibilityOptions.map((option) => (
        <div key={option.value}>
          <Label
            htmlFor={option.value}
            className={cn(
              'flex items-start gap-3 rounded-lg border p-4 cursor-pointer transition-colors',
              'hover:bg-accent/50',
              value === option.value ? 'border-primary bg-accent' : 'border-border',
              disabled && 'opacity-50 cursor-not-allowed'
            )}
          >
            <RadioGroupItem value={option.value} id={option.value} className="mt-1" />
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1">
                {option.icon}
                <span className="font-medium">{option.label}</span>
              </div>
              <p className="text-sm text-muted-foreground">{option.description}</p>
            </div>
          </Label>
        </div>
      ))}
    </RadioGroup>
  );
}

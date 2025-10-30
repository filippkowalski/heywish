'use client';

import { useState } from 'react';
import { Clipboard, Check, Loader2 } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface UrlInputProps {
  value: string;
  onChange: (value: string) => void;
  onPaste?: (url: string) => void;
  placeholder?: string;
  disabled?: boolean;
  isLoading?: boolean;
}

export function UrlInput({
  value,
  onChange,
  onPaste,
  placeholder = 'https://example.com/product',
  disabled = false,
  isLoading = false,
}: UrlInputProps) {
  const [showCopied, setShowCopied] = useState(false);

  const handlePasteClick = async () => {
    try {
      const text = await navigator.clipboard.readText();
      if (text) {
        onChange(text);
        if (onPaste) {
          onPaste(text);
        }
        setShowCopied(true);
        setTimeout(() => setShowCopied(false), 2000);
      }
    } catch (err) {
      console.error('Failed to read clipboard:', err);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;
    onChange(newValue);
  };

  const handleInputPaste = (e: React.ClipboardEvent<HTMLInputElement>) => {
    const pastedText = e.clipboardData.getData('text');
    if (pastedText && onPaste) {
      // Small delay to ensure the input value is updated first
      setTimeout(() => {
        onPaste(pastedText);
      }, 100);
    }
  };

  return (
    <div className="relative">
      <Input
        type="url"
        value={value}
        onChange={handleInputChange}
        onPaste={handleInputPaste}
        placeholder={placeholder}
        disabled={disabled || isLoading}
        className="pr-24"
      />
      <div className="absolute right-1 top-1/2 -translate-y-1/2 flex items-center gap-1">
        {isLoading && <Loader2 className="h-4 w-4 animate-spin text-primary" />}
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={handlePasteClick}
          disabled={disabled || isLoading}
          className={cn('h-7 px-2', showCopied && 'text-green-600')}
        >
          {showCopied ? (
            <>
              <Check className="h-4 w-4 mr-1" />
              <span className="text-xs">Pasted</span>
            </>
          ) : (
            <>
              <Clipboard className="h-4 w-4 mr-1" />
              <span className="text-xs">Paste</span>
            </>
          )}
        </Button>
      </div>
    </div>
  );
}

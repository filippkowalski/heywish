'use client';

import { useCallback, useMemo, useState } from 'react';
import { Link2, Check } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface ShareButtonProps {
  path: string;
  label?: string;
  className?: string;
}

export function ShareButton({ path, label = 'Copy link', className }: ShareButtonProps) {
  const [copied, setCopied] = useState(false);

  const shareUrl = useMemo(() => {
    if (!path) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (typeof window !== 'undefined') {
      return `${window.location.origin}${path.startsWith('/') ? path : `/${path}`}`;
    }
    return path.startsWith('/') ? path : `/${path}`;
  }, [path]);

  const handleCopy = useCallback(async () => {
    if (!shareUrl) return;

    try {
      if (typeof navigator !== 'undefined' && navigator.clipboard) {
        await navigator.clipboard.writeText(shareUrl);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      }
    } catch (error) {
      console.error('Failed to copy to clipboard:', error);
    }
  }, [shareUrl]);

  return (
    <Button
      type="button"
      variant={copied ? 'secondary' : 'outline'}
      size="sm"
      onClick={handleCopy}
      className={cn('gap-2', className)}
      disabled={!shareUrl}
    >
      {copied ? <Check className="h-4 w-4" /> : <Link2 className="h-4 w-4" />}
      <span>{copied ? 'Link copied' : label}</span>
    </Button>
  );
}

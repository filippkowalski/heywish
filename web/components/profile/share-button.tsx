'use client';

import { useCallback, useMemo, useState } from 'react';
import { Share2, Check } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface ShareButtonProps {
  path: string;
  label?: string;
  className?: string;
  title?: string;
  text?: string;
}

export function ShareButton({ path, label = 'Share', className, title, text }: ShareButtonProps) {
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

  const handleShare = useCallback(async () => {
    if (!shareUrl) return;

    const resolvedTitle = title ?? 'HeyWish wishlist';
    const resolvedText = text ?? 'Explore this wishlist on HeyWish';

    try {
      if (typeof navigator !== 'undefined' && navigator.share) {
        await navigator.share({
          url: shareUrl,
          title: resolvedTitle,
          text: resolvedText,
        });
        return;
      }
    } catch (error) {
      console.warn('Share failed, falling back to clipboard:', error);
    }

    try {
      if (typeof navigator !== 'undefined' && navigator.clipboard) {
        await navigator.clipboard.writeText(shareUrl);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      }
    } catch (error) {
      console.error('Failed to copy to clipboard:', error);
    }
  }, [shareUrl, text, title]);

  return (
    <Button
      variant={copied ? 'secondary' : 'outline'}
      size="sm"
      onClick={handleShare}
      className={cn('gap-2', className)}
      disabled={!shareUrl}
    >
      {copied ? <Check className="h-4 w-4" /> : <Share2 className="h-4 w-4" />}
      <span>{copied ? 'Link copied' : label}</span>
    </Button>
  );
}

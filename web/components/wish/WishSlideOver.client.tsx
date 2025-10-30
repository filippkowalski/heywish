'use client';

import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { toast } from 'sonner';
import { useDebouncedCallback } from 'use-debounce';
import { SlideOver } from '@/components/ui/slide-over.client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { ImageUploader } from '@/components/form/ImageUploader';
import { CurrencySelect } from '@/components/form/CurrencySelect';
import { UrlInput } from '@/components/form/UrlInput';
import { useApiAuth } from '@/lib/hooks/useApiAuth';
import { compressWishImage } from '@/lib/utils/imageCompression';
import { uploadToR2 } from '@/lib/utils/upload';
import { wishSchema, type WishFormData } from '@/lib/utils/validation';
import type { Wish, Wishlist } from '@/lib/api';
import { Loader2, Sparkles } from 'lucide-react';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

interface WishSlideOverProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  wishlistId?: string;
  wish?: Wish;
  wishlists: Wishlist[];
}

export function WishSlideOver({ open, onClose, onSuccess, wishlistId, wish, wishlists }: WishSlideOverProps) {
  const api = useApiAuth();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isScrapingUrl, setIsScrapingUrl] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
    reset,
  } = useForm<WishFormData>({
    resolver: zodResolver(wishSchema),
    defaultValues: {
      wishlistId: wishlistId || undefined,
      title: '',
      description: '',
      url: '',
      price: 0,
      currency: 'USD',
      images: [],
    },
  });

  const urlValue = watch('url');
  const images = watch('images') || [];
  const currency = watch('currency');
  const selectedWishlistId = watch('wishlistId');

  // Reset form when wish changes or modal opens
  useEffect(() => {
    if (open) {
      if (wish) {
        reset({
          wishlistId: wishlistId || undefined,
          title: wish.title,
          description: wish.description || '',
          url: wish.url || '',
          price: wish.price || 0,
          currency: wish.currency || 'USD',
          images: wish.images || [],
        });
      } else {
        reset({
          wishlistId: wishlistId || undefined,
          title: '',
          description: '',
          url: '',
          price: 0,
          currency: 'USD',
          images: [],
        });
      }
    }
  }, [open, wish, wishlistId, reset]);

  // Debounced URL scraping
  const scrapeUrl = useDebouncedCallback(async (url: string) => {
    if (!url || !url.startsWith('http')) return;

    setIsScrapingUrl(true);

    try {
      const metadata = await api.scrapeUrl(url);

      if (metadata.success) {
        let fieldsUpdated = 0;

        // Auto-fill fields
        if (metadata.title) {
          setValue('title', metadata.title);
          fieldsUpdated++;
        }
        if (metadata.description) {
          setValue('description', metadata.description);
          fieldsUpdated++;
        }
        if (metadata.price) {
          setValue('price', metadata.price);
          fieldsUpdated++;
        }
        if (metadata.currency) {
          setValue('currency', metadata.currency);
          fieldsUpdated++;
        }
        if (metadata.image) {
          setValue('images', [metadata.image]);
          fieldsUpdated++;
        }

        if (fieldsUpdated > 0) {
          const source = metadata.source || 'URL';
          toast.success(`✨ Product details loaded from ${source}!`);
        } else {
          toast.info('Could not extract product details from this URL');
        }
      } else {
        toast.info('Could not extract product details from this URL');
      }
    } catch (error) {
      // Fail silently for URL scraping errors
      toast.error('Failed to load product details');
    } finally {
      setIsScrapingUrl(false);
    }
  }, 800);

  const handleUrlPaste = (url: string) => {
    scrapeUrl(url);
  };

  const handleImageUpload = async (file: File): Promise<string> => {
    try {
      // Compress image
      const compressedFile = await compressWishImage(file);

      // Upload to R2
      const publicUrl = await uploadToR2(compressedFile, () =>
        api.getWishImageUploadUrl(compressedFile.name, compressedFile.type)
      );

      return publicUrl;
    } catch (error) {
      throw new Error('Failed to upload image');
    }
  };

  const onSubmit = async (data: WishFormData) => {
    setIsSubmitting(true);

    try {
      const payload = {
        wishlistId: data.wishlistId || wishlistId,
        title: data.title,
        description: data.description || undefined,
        url: data.url || undefined,
        price: data.price || undefined,
        currency: data.currency,
        images: data.images && data.images.length > 0 ? data.images : undefined,
      };

      if (wish) {
        // Update existing wish
        await api.updateWish(wish.id, payload);
        toast.success('Wish updated successfully');
      } else {
        // Create new wish
        await api.createWish(payload);
        toast.success('Wish added successfully');
      }

      onSuccess();
      onClose();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to save wish';
      toast.error(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <SlideOver
      open={open}
      onClose={onClose}
      title={wish ? 'Edit Wish' : 'Add Wish'}
      description={wish ? 'Update wish details' : 'Add a new item to your wishlist'}
      size="3xl"
    >
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* Wishlist Selector */}
        <div className="space-y-2">
          <Label htmlFor="wishlist">
            Wishlist
          </Label>
          <Select
            value={selectedWishlistId || 'none'}
            onValueChange={(value) => setValue('wishlistId', value === 'none' ? undefined : value)}
            disabled={isSubmitting || isScrapingUrl}
          >
            <SelectTrigger id="wishlist">
              <SelectValue placeholder="Select a wishlist (optional)" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="none">
                <span className="text-muted-foreground">No wishlist (uncategorized)</span>
              </SelectItem>
              {wishlists.map((wishlist) => (
                <SelectItem key={wishlist.id} value={wishlist.id}>
                  {wishlist.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <p className="text-xs text-muted-foreground">
            Choose a wishlist or leave uncategorized
          </p>
        </div>

        {/* URL Input */}
        <div className="space-y-2">
          <Label htmlFor="url">
            Product URL
            {isScrapingUrl && (
              <span className="ml-2 text-xs text-primary inline-flex items-center gap-1">
                <Sparkles className="h-3 w-3" />
                Fetching details...
              </span>
            )}
          </Label>
          <UrlInput
            value={urlValue || ''}
            onChange={(value) => setValue('url', value)}
            onPaste={handleUrlPaste}
            placeholder="Paste product URL (optional)"
            disabled={isSubmitting}
            isLoading={isScrapingUrl}
          />
          <p className="text-xs text-muted-foreground">
            Paste a product URL and we&apos;ll try to fill in the details automatically
          </p>
          {errors.url && <p className="text-sm text-destructive">{errors.url.message}</p>}
        </div>

        {/* Title */}
        <div className="space-y-2">
          <Label htmlFor="title">
            Title <span className="text-destructive">*</span>
          </Label>
          <Input
            id="title"
            placeholder="e.g., Nike Air Max 90"
            {...register('title')}
            disabled={isSubmitting || isScrapingUrl}
          />
          {errors.title && <p className="text-sm text-destructive">{errors.title.message}</p>}
        </div>

        {/* Description */}
        <div className="space-y-2">
          <Label htmlFor="description">Description</Label>
          <Textarea
            id="description"
            placeholder="Add details about size, color, or notes (optional)"
            rows={3}
            {...register('description')}
            disabled={isSubmitting || isScrapingUrl}
          />
          {errors.description && <p className="text-sm text-destructive">{errors.description.message}</p>}
        </div>

        {/* Price & Currency */}
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="price">Price</Label>
            <Input
              id="price"
              type="number"
              step="0.01"
              placeholder="0.00"
              {...register('price', { valueAsNumber: true })}
              disabled={isSubmitting || isScrapingUrl}
            />
            {errors.price && <p className="text-sm text-destructive">{errors.price.message}</p>}
          </div>

          <div className="space-y-2">
            <Label>Currency</Label>
            <CurrencySelect
              value={currency}
              onValueChange={(value) => setValue('currency', value)}
              disabled={isSubmitting || isScrapingUrl}
            />
            {errors.currency && <p className="text-sm text-destructive">{errors.currency.message}</p>}
          </div>
        </div>

        {/* Image */}
        <div className="space-y-2">
          <Label>Product Image</Label>
          <ImageUploader
            value={images[0]}
            onChange={(url) => setValue('images', url ? [url] : [])}
            onUpload={handleImageUpload}
            disabled={isSubmitting || isScrapingUrl}
            aspectRatio="square"
            maxSizeMB={5}
          />
          {errors.images && <p className="text-sm text-destructive">{errors.images.message}</p>}
        </div>

        {/* Actions */}
        <div className="flex items-center gap-3 pt-6 border-t sticky bottom-0 bg-background pb-6 -mb-6">
          <Button type="button" variant="outline" onClick={onClose} disabled={isSubmitting} className="flex-1">
            Cancel
          </Button>
          <Button type="submit" disabled={isSubmitting || isScrapingUrl} className="flex-1">
            {isSubmitting ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                {wish ? 'Updating...' : 'Adding...'}
              </>
            ) : (
              <>{wish ? 'Update Wish' : 'Add Wish'}</>
            )}
          </Button>
        </div>
      </form>
    </SlideOver>
  );
}

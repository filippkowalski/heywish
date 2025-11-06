'use client';

import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { toast } from 'sonner';
import { SlideOver } from '@/components/ui/slide-over.client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { ImageUploader } from '@/components/form/ImageUploader';
import { VisibilityRadioGroup } from '@/components/form/VisibilityRadioGroup';
import { useApiAuth } from '@/lib/hooks/useApiAuth';
import { compressWishlistCover } from '@/lib/utils/imageCompression';
import { uploadToR2 } from '@/lib/utils/upload';
import { wishlistSchema, type WishlistFormData } from '@/lib/utils/validation';
import type { Wishlist } from '@/lib/api';
import { Loader2 } from 'lucide-react';

interface WishlistSlideOverProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  wishlist?: Wishlist;
}

export function WishlistSlideOver({ open, onClose, onSuccess, wishlist }: WishlistSlideOverProps) {
  const api = useApiAuth();
  const [isSubmitting, setIsSubmitting] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
    reset,
  } = useForm<WishlistFormData>({
    resolver: zodResolver(wishlistSchema),
    defaultValues: {
      name: '',
      description: '',
      visibility: 'public',
      coverImageUrl: '',
    },
  });

  const coverImageUrl = watch('coverImageUrl');
  const visibility = watch('visibility');

  // Reset form when wishlist changes or modal opens
  useEffect(() => {
    if (open) {
      if (wishlist) {
        reset({
          name: wishlist.name,
          description: wishlist.description || '',
          visibility: wishlist.visibility,
          coverImageUrl: wishlist.coverImageUrl || '',
        });
      } else {
        reset({
          name: '',
          description: '',
          visibility: 'public',
          coverImageUrl: '',
        });
      }
    }
  }, [open, wishlist, reset]);

  const handleImageUpload = async (file: File): Promise<string> => {
    try {
      // Compress image
      const compressedFile = await compressWishlistCover(file);

      // Upload to R2
      const publicUrl = await uploadToR2(compressedFile, () =>
        api.getWishlistCoverUploadUrl(compressedFile.name, compressedFile.type)
      );

      return publicUrl;
    } catch (error) {
      console.error('Image upload error:', error);
      throw new Error('Failed to upload image');
    }
  };

  const onSubmit = async (data: WishlistFormData) => {
    // Prevent editing of synthetic "All Wishes" wishlist
    if (wishlist && wishlist.id === 'uncategorized') {
      toast.error('Cannot edit this wishlist');
      return;
    }

    setIsSubmitting(true);

    try {
      const payload = {
        name: data.name,
        description: data.description || undefined,
        visibility: data.visibility,
        coverImageUrl: data.coverImageUrl || undefined,
      };

      if (wishlist) {
        // Update existing wishlist
        await api.updateWishlist(wishlist.id, payload);
        toast.success('Wishlist updated successfully');
      } else {
        // Create new wishlist
        await api.createWishlist(payload);
        toast.success('Wishlist created successfully');
      }

      onSuccess();
      onClose();
    } catch (error) {
      console.error('Error saving wishlist:', error);
      const message = error instanceof Error ? error.message : 'Failed to save wishlist';
      toast.error(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <SlideOver
      open={open}
      onClose={onClose}
      title={wishlist ? 'Edit Wishlist' : 'Create Wishlist'}
      description={wishlist ? 'Update your wishlist details' : 'Create a new wishlist to organize your wishes'}
      size="xl"
    >
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* Name */}
        <div className="space-y-2">
          <Label htmlFor="name">
            Name <span className="text-destructive">*</span>
          </Label>
          <Input
            id="name"
            placeholder="e.g., Birthday 2025, Christmas Gifts"
            {...register('name')}
            disabled={isSubmitting}
          />
          {errors.name && <p className="text-sm text-destructive">{errors.name.message}</p>}
        </div>

        {/* Description */}
        <div className="space-y-2">
          <Label htmlFor="description">Description</Label>
          <Textarea
            id="description"
            placeholder="Add a description for this wishlist (optional)"
            rows={3}
            {...register('description')}
            disabled={isSubmitting}
          />
          {errors.description && <p className="text-sm text-destructive">{errors.description.message}</p>}
        </div>

        {/* Visibility */}
        <div className="space-y-2">
          <Label>
            Visibility <span className="text-destructive">*</span>
          </Label>
          <VisibilityRadioGroup
            value={visibility}
            onValueChange={(value) => setValue('visibility', value as 'public' | 'friends' | 'private')}
            disabled={isSubmitting}
          />
          {errors.visibility && <p className="text-sm text-destructive">{errors.visibility.message}</p>}
        </div>

        {/* Cover Image */}
        <div className="space-y-2">
          <Label>Cover Image</Label>
          <ImageUploader
            value={coverImageUrl}
            onChange={(url) => setValue('coverImageUrl', url || '')}
            onUpload={handleImageUpload}
            disabled={isSubmitting}
            aspectRatio="video"
            maxSizeMB={5}
          />
          {errors.coverImageUrl && <p className="text-sm text-destructive">{errors.coverImageUrl.message}</p>}
        </div>

        {/* Actions */}
        <div className="flex items-center gap-3 pt-6 border-t sticky bottom-0 bg-background pb-6 -mb-6">
          <Button type="button" variant="outline" onClick={onClose} disabled={isSubmitting} className="flex-1">
            Cancel
          </Button>
          <Button type="submit" disabled={isSubmitting} className="flex-1">
            {isSubmitting ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                {wishlist ? 'Updating...' : 'Creating...'}
              </>
            ) : (
              <>{wishlist ? 'Update Wishlist' : 'Create Wishlist'}</>
            )}
          </Button>
        </div>
      </form>
    </SlideOver>
  );
}

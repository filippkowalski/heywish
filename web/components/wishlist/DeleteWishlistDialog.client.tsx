'use client';

import { useState } from 'react';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { useApiAuth } from '@/lib/hooks/useApiAuth';
import type { Wishlist } from '@/lib/api';

interface DeleteWishlistDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  wishlist: Wishlist;
  onSuccess: () => void;
}

export function DeleteWishlistDialog({ open, onOpenChange, wishlist, onSuccess }: DeleteWishlistDialogProps) {
  const api = useApiAuth();
  const [isDeleting, setIsDeleting] = useState(false);

  const handleDelete = async () => {
    // Prevent deletion of synthetic "All Wishes" wishlist
    if (wishlist.id === 'uncategorized') {
      toast.error('Cannot delete this wishlist');
      onOpenChange(false);
      return;
    }

    setIsDeleting(true);

    try {
      await api.deleteWishlist(wishlist.id);
      toast.success('Wishlist deleted successfully');
      onSuccess();
      onOpenChange(false);
    } catch (error) {
      console.error('Error deleting wishlist:', error);
      const message = error instanceof Error ? error.message : 'Failed to delete wishlist';
      toast.error(message);
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Delete Wishlist?</AlertDialogTitle>
          <AlertDialogDescription className="space-y-2">
            <p>
              Are you sure you want to delete <span className="font-semibold">&quot;{wishlist.name}&quot;</span>?
            </p>
            {wishlist.wishCount > 0 && (
              <p className="text-destructive font-medium">
                This will permanently delete {wishlist.wishCount} {wishlist.wishCount === 1 ? 'wish' : 'wishes'}. This action cannot be undone.
              </p>
            )}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={isDeleting}>Cancel</AlertDialogCancel>
          <AlertDialogAction
            onClick={(e) => {
              e.preventDefault();
              handleDelete();
            }}
            disabled={isDeleting}
            className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
          >
            {isDeleting ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Deleting...
              </>
            ) : (
              'Delete Wishlist'
            )}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}

'use client';

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import type { Wishlist } from '@/lib/api';
import { Pencil, Trash2, Eye, EyeOff, Lock } from 'lucide-react';
import { Badge } from '@/components/ui/badge';

interface ManageWishlistsDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  wishlists: Wishlist[];
  onEdit: (wishlist: Wishlist) => void;
  onDelete: (wishlist: Wishlist) => void;
}

export function ManageWishlistsDialog({
  open,
  onOpenChange,
  wishlists,
  onEdit,
  onDelete,
}: ManageWishlistsDialogProps) {

  const getVisibilityIcon = (visibility: string) => {
    switch (visibility) {
      case 'public':
        return <Eye className="h-3 w-3" />;
      case 'private':
        return <Lock className="h-3 w-3" />;
      case 'friends':
        return <EyeOff className="h-3 w-3" />;
      default:
        return null;
    }
  };

  const getVisibilityLabel = (visibility: string) => {
    switch (visibility) {
      case 'public':
        return 'Public';
      case 'private':
        return 'Private';
      case 'friends':
        return 'Friends';
      default:
        return visibility;
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-2xl max-h-[80vh] flex flex-col">
        <DialogHeader>
          <DialogTitle>Manage Wishlists</DialogTitle>
          <DialogDescription>
            Edit and delete your wishlists
          </DialogDescription>
        </DialogHeader>

        <div className="flex-1 overflow-y-auto py-4 px-2">
          {wishlists.length === 0 ? (
            <div className="text-center py-12 text-muted-foreground">
              <p>No wishlists yet</p>
              <p className="text-sm mt-1">Create your first wishlist to get started</p>
            </div>
          ) : (
            <div className="space-y-3 px-2">
              {wishlists.map((wishlist) => {
                const wishCount = wishlist.wishes?.length ?? wishlist.items?.length ?? wishlist.wishCount ?? 0;

                return (
                  <div
                    key={wishlist.id}
                    className="group flex items-center gap-3 p-4 rounded-lg border bg-card transition-all hover:shadow-md"
                  >

                    {/* Wishlist info */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold truncate">{wishlist.name}</h3>
                        <Badge variant="secondary" className="flex items-center gap-1 text-xs">
                          {getVisibilityIcon(wishlist.visibility)}
                          <span>{getVisibilityLabel(wishlist.visibility)}</span>
                        </Badge>
                      </div>
                      {wishlist.description && (
                        <p className="text-sm text-muted-foreground line-clamp-1">
                          {wishlist.description}
                        </p>
                      )}
                      <p className="text-xs text-muted-foreground mt-1">
                        {wishCount} {wishCount === 1 ? 'wish' : 'wishes'}
                      </p>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2 flex-shrink-0">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={(e) => {
                          e.stopPropagation();
                          onEdit(wishlist);
                        }}
                        className="h-8 w-8 p-0"
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={(e) => {
                          e.stopPropagation();
                          onDelete(wishlist);
                        }}
                        className="h-8 w-8 p-0 text-destructive hover:text-destructive"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        <div className="flex justify-end gap-2 border-t pt-4 px-2 pb-2">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Done
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

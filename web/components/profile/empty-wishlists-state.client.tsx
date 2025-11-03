'use client';

import { Gift, Plus } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useOwnership } from "@/components/profile/ProfileOwnershipWrapper.client";

interface EmptyWishlistsStateProps {
  username: string;
}

export function EmptyWishlistsState({ username }: EmptyWishlistsStateProps) {
  const ownership = useOwnership();

  // If the user is the owner, show action buttons
  if (ownership?.isOwner) {
    return (
      <section className="container mx-auto px-4 py-12 md:px-6">
        <Card className="bg-muted/40">
          <CardContent className="flex flex-col items-center gap-6 p-10 text-center">
            <Gift className="h-12 w-12 text-muted-foreground" />
            <div>
              <h2 className="text-xl font-semibold mb-2">Start your first wishlist</h2>
              <p className="text-sm text-muted-foreground max-w-md">
                Create a wishlist to organize your wishes and share them with friends and family.
              </p>
            </div>
            <Button
              onClick={ownership.openNewWishlist}
              size="lg"
              className="gap-2"
            >
              <Plus className="h-4 w-4" />
              Create Wishlist
            </Button>
          </CardContent>
        </Card>
      </section>
    );
  }

  // If not the owner, show the default message
  return (
    <section className="container mx-auto px-4 py-12 md:px-6">
      <Card className="bg-muted/40">
        <CardContent className="flex flex-col items-center gap-4 p-10 text-center">
          <Gift className="h-10 w-10 text-muted-foreground" />
          <div>
            <h2 className="text-lg font-semibold">No public wishlists yet</h2>
            <p className="text-sm text-muted-foreground">
              Ask @{username} to share a list from the mobile app.
            </p>
          </div>
        </CardContent>
      </Card>
    </section>
  );
}

'use client';

import { useState, useEffect, useMemo } from 'react';
import { useAuth } from '@/lib/auth/AuthContext.client';
import { useApiAuth } from '@/lib/hooks/useApiAuth';
import { SignInModal } from '@/components/auth/SignInModal.client';
import { WishSlideOver } from '@/components/wish/WishSlideOver.client';
import { InspoGrid } from '@/components/inspo/inspo-grid';
import { inspoItems, categories, type InspoItem } from '@/lib/inspo/inspo-items';
import type { Wishlist } from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Sparkles } from 'lucide-react';

export default function InspoPage() {
  const { user, backendUser } = useAuth();
  const { getMyWishlists } = useApiAuth();
  const isLoggedIn = !!user && !!backendUser;

  // State management
  const [showSignIn, setShowSignIn] = useState(false);
  const [showWishModal, setShowWishModal] = useState(false);
  const [selectedItem, setSelectedItem] = useState<InspoItem | null>(null);
  const [wishlists, setWishlists] = useState<Wishlist[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  // Fetch user's wishlists when logged in
  useEffect(() => {
    if (isLoggedIn) {
      const fetchWishlists = async () => {
        try {
          const data = await getMyWishlists();
          setWishlists(data);
        } catch (error) {
          console.error('Failed to fetch wishlists:', error);
        }
      };

      fetchWishlists();
    }
  }, [isLoggedIn, getMyWishlists]);

  // Filter items by category
  const filteredItems = useMemo(() => {
    if (selectedCategory === 'all') {
      return inspoItems;
    }
    return inspoItems.filter((item) => item.category === selectedCategory);
  }, [selectedCategory]);

  // Handle save button click
  const handleSaveItem = (item: InspoItem) => {
    setSelectedItem(item);

    if (!isLoggedIn) {
      setShowSignIn(true);
      return;
    }

    setShowWishModal(true);
  };

  // After user signs in, open the wish modal
  useEffect(() => {
    if (isLoggedIn && selectedItem && !showWishModal) {
      setShowWishModal(true);
    }
  }, [isLoggedIn, selectedItem, showWishModal]);

  // Prepare prefilled data for WishSlideOver
  const prefilledData = selectedItem
    ? {
        title: selectedItem.title,
        description: selectedItem.description,
        url: selectedItem.url,
        price: selectedItem.price,
        currency: selectedItem.currency,
        images: [selectedItem.image],
      }
    : undefined;

  return (
    <div className="min-h-screen bg-background">
      {/* Hero Section */}
      <div className="border-b bg-gradient-to-b from-primary/5 to-background">
        <div className="container mx-auto px-4 py-12 md:py-16">
          <div className="mx-auto max-w-3xl text-center">
            <div className="mb-4 inline-flex items-center gap-2 rounded-full bg-primary/10 px-4 py-1.5 text-sm font-medium text-primary">
              <Sparkles className="h-4 w-4" />
              Gift Inspiration
            </div>
            <h1 className="mb-4 text-4xl font-bold tracking-tight md:text-5xl">
              Discover Amazing Gift Ideas
            </h1>
            <p className="text-lg text-muted-foreground">
              Curated collection of trending gifts and must-have items. Save any item to your
              wishlist with a single click.
            </p>
          </div>
        </div>
      </div>

      {/* Category Filter */}
      <div className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto px-4 py-4">
          <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
            <Button
              variant={selectedCategory === 'all' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setSelectedCategory('all')}
              className="whitespace-nowrap"
            >
              All Items
            </Button>
            {categories.map((category) => (
              <Button
                key={category}
                variant={selectedCategory === category ? 'default' : 'outline'}
                size="sm"
                onClick={() => setSelectedCategory(category)}
                className="whitespace-nowrap"
              >
                {category}
              </Button>
            ))}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="container mx-auto px-4 py-8">
        <div className="mb-6">
          <p className="text-sm text-muted-foreground">
            Showing {filteredItems.length} {filteredItems.length === 1 ? 'item' : 'items'}
            {selectedCategory !== 'all' && ` in ${selectedCategory}`}
          </p>
        </div>

        <InspoGrid items={filteredItems} onSaveItem={handleSaveItem} />
      </div>

      {/* Sign In Modal */}
      <SignInModal open={showSignIn} onOpenChange={setShowSignIn} />

      {/* Wish Slide Over */}
      {isLoggedIn && (
        <WishSlideOver
          open={showWishModal}
          onClose={() => {
            setShowWishModal(false);
            setSelectedItem(null);
          }}
          onSuccess={() => {
            setShowWishModal(false);
            setSelectedItem(null);
          }}
          wishlists={wishlists}
          prefilledData={prefilledData}
        />
      )}
    </div>
  );
}

'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { api, Wishlist } from '@/lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { ExternalLink, Heart, Gift, Share2 } from 'lucide-react';
import Image from 'next/image';

export default function PublicWishlistPage() {
  const params = useParams();
  const token = params.token as string;
  const [wishlist, setWishlist] = useState<Wishlist | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reservingItems, setReservingItems] = useState<Set<string>>(new Set());

  useEffect(() => {
    const fetchWishlist = async () => {
      try {
        setLoading(true);
        const response = await api.getPublicWishlist(token);
        setWishlist(response.wishlist);
      } catch (err: unknown) {
        console.error('Error fetching wishlist:', err);
        const error = err as { response?: { status?: number } };
        if (error.response?.status === 404) {
          setError('Wishlist not found');
        } else if (error.response?.status === 403) {
          setError('This wishlist is private');
        } else {
          setError('Failed to load wishlist');
        }
      } finally {
        setLoading(false);
      }
    };

    if (token) {
      fetchWishlist();
    }
  }, [token]);

  const handleReserveWish = async (wishId: string) => {
    try {
      setReservingItems(prev => new Set(prev).add(wishId));
      await api.reserveWish(wishId, 'Reserved via shared link');
      
      // Update the local wishlist state
      setWishlist(prev => {
        if (!prev) return prev;
        return {
          ...prev,
          wishes: prev.wishes?.map(wish => 
            wish.id === wishId 
              ? { ...wish, status: 'reserved' as const }
              : wish
          )
        };
      });
    } catch (err: unknown) {
      console.error('Error reserving wish:', err);
      alert('Failed to reserve item. Please try again.');
    } finally {
      setReservingItems(prev => {
        const next = new Set(prev);
        next.delete(wishId);
        return next;
      });
    }
  };

  const handleShare = async () => {
    try {
      await navigator.share({
        title: `${wishlist?.name} - HeyWish`,
        text: `Check out ${wishlist?.name} on HeyWish!`,
        url: window.location.href,
      });
    } catch {
      // Fallback to copying to clipboard
      await navigator.clipboard.writeText(window.location.href);
      alert('Link copied to clipboard!');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-foreground mx-auto mb-4"></div>
          <p className="text-muted-foreground">Loading wishlist...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center">
          <Heart className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
          <h1 className="text-2xl font-semibold mb-2">{error}</h1>
          <p className="text-muted-foreground">
            This wishlist may be private or the link may have expired.
          </p>
        </div>
      </div>
    );
  }

  if (!wishlist) return null;

  // Handle both 'wishes' and 'items' fields from different API responses
  const allWishes = wishlist.wishes || wishlist.items || [];
  const availableItems = allWishes.filter(wish => wish.status === 'available');
  const reservedItems = allWishes.filter(wish => wish.status === 'reserved');

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b bg-card/50 backdrop-blur-sm sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <Avatar className="h-10 w-10">
                <AvatarFallback className="bg-primary text-primary-foreground">
                  {wishlist.owner_name?.charAt(0).toUpperCase() || 'U'}
                </AvatarFallback>
              </Avatar>
              <div>
                <h1 className="text-xl font-semibold">{wishlist.owner_name}</h1>
                <p className="text-sm text-muted-foreground">
                  {allWishes.length} items
                </p>
              </div>
            </div>
            <Button 
              variant="outline" 
              size="sm" 
              onClick={handleShare}
              className="flex items-center space-x-2"
            >
              <Share2 className="h-4 w-4" />
              <span>Share</span>
            </Button>
          </div>
          {wishlist.description && (
            <p className="text-muted-foreground mt-3 text-sm">
              {wishlist.description}
            </p>
          )}
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        {allWishes.length === 0 ? (
          <div className="text-center py-12">
            <Gift className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
            <h2 className="text-xl font-semibold mb-2">No items yet</h2>
            <p className="text-muted-foreground">
              This wishlist is empty at the moment.
            </p>
          </div>
        ) : (
          <div className="space-y-8">
            {/* Available Items */}
            {availableItems.length > 0 && (
              <section>
                <h2 className="text-lg font-semibold mb-4 flex items-center">
                  <Heart className="h-5 w-5 mr-2" />
                  Available ({availableItems.length})
                </h2>
                <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                  {availableItems.map((wish) => (
                    <Card key={wish.id} className="overflow-hidden hover:shadow-lg transition-shadow">
                      {wish.images && wish.images.length > 0 && (
                        <div className="relative h-48 bg-muted">
                          <Image
                            src={wish.images[0]}
                            alt={wish.title}
                            fill
                            className="object-cover"
                            onError={(e) => {
                              e.currentTarget.style.display = 'none';
                            }}
                          />
                        </div>
                      )}
                      <CardHeader className="pb-2">
                        <div className="flex justify-between items-start">
                          <CardTitle className="text-base line-clamp-2">
                            {wish.title}
                          </CardTitle>
                          {wish.price && (
                            <Badge variant="secondary" className="ml-2 shrink-0">
                              ${wish.price.toFixed(2)}
                            </Badge>
                          )}
                        </div>
                      </CardHeader>
                      <CardContent className="pt-0">
                        {wish.description && (
                          <p className="text-sm text-muted-foreground mb-3 line-clamp-2">
                            {wish.description}
                          </p>
                        )}
                        <div className="flex gap-2">
                          <Button
                            onClick={() => handleReserveWish(wish.id)}
                            disabled={reservingItems.has(wish.id)}
                            className="flex-1"
                            size="sm"
                          >
                            <Gift className="h-4 w-4 mr-2" />
                            {reservingItems.has(wish.id) ? 'Reserving...' : 'Reserve'}
                          </Button>
                          {wish.url && (
                            <Button
                              variant="outline"
                              size="sm"
                              asChild
                            >
                              <a
                                href={wish.url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex items-center"
                              >
                                <ExternalLink className="h-4 w-4" />
                              </a>
                            </Button>
                          )}
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              </section>
            )}

            {/* Reserved Items */}
            {reservedItems.length > 0 && (
              <section>
                <h2 className="text-lg font-semibold mb-4 flex items-center text-muted-foreground">
                  <Gift className="h-5 w-5 mr-2" />
                  Reserved ({reservedItems.length})
                </h2>
                <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                  {reservedItems.map((wish) => (
                    <Card key={wish.id} className="overflow-hidden opacity-75">
                      {wish.images && wish.images.length > 0 && (
                        <div className="relative h-48 bg-muted">
                          <Image
                            src={wish.images[0]}
                            alt={wish.title}
                            fill
                            className="object-cover grayscale"
                            onError={(e) => {
                              e.currentTarget.style.display = 'none';
                            }}
                          />
                        </div>
                      )}
                      <CardHeader className="pb-2">
                        <div className="flex justify-between items-start">
                          <CardTitle className="text-base line-clamp-2">
                            {wish.title}
                          </CardTitle>
                          <Badge className="ml-2 shrink-0">Reserved</Badge>
                        </div>
                      </CardHeader>
                      <CardContent className="pt-0">
                        {wish.description && (
                          <p className="text-sm text-muted-foreground mb-3 line-clamp-2">
                            {wish.description}
                          </p>
                        )}
                        <p className="text-sm text-muted-foreground">
                          This item has been reserved by someone.
                        </p>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              </section>
            )}
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t mt-12 py-8">
        <div className="container mx-auto px-4 text-center">
          <p className="text-sm text-muted-foreground">
            Powered by <span className="font-semibold">HeyWish</span>
          </p>
        </div>
      </footer>
    </div>
  );
}

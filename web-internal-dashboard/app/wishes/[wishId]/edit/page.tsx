'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import useSWR from 'swr';
import { DashboardLayout } from '@/components/dashboard-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { getWish, updateWish, type Wish } from '@/lib/api';
import { toast } from 'sonner';
import { ArrowLeft, Loader2, RefreshCcw, Save } from 'lucide-react';

interface PublicWishlist {
  id: string;
  name: string;
  visibility?: string;
}

export default function EditWishPage() {
  const params = useParams<{ wishId?: string }>();
  const router = useRouter();
  const wishIdParam = params?.wishId;
  const wishId = Array.isArray(wishIdParam) ? wishIdParam[0] : wishIdParam;

  const { data, error, isLoading, mutate } = useSWR(
    wishId ? `/admin/wishes/${wishId}` : null,
    () => getWish(wishId!)
  );

  const wish = data?.wish;

  const [username, setUsername] = useState('');
  const [wishlistId, setWishlistId] = useState('');
  const [wishlists, setWishlists] = useState<PublicWishlist[]>([]);
  const [wishlistsError, setWishlistsError] = useState('');
  const [isWishlistsLoading, setIsWishlistsLoading] = useState(false);

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [url, setUrl] = useState('');
  const [price, setPrice] = useState('');
  const [currency, setCurrency] = useState('USD');
  const [images, setImages] = useState('');
  const [priority, setPriority] = useState('3');
  const [quantity, setQuantity] = useState('1');

  const [isSaving, setIsSaving] = useState(false);

  const populateFormFromWish = (targetWish: Wish) => {
    setUsername(targetWish.username || '');
    setWishlistId(targetWish.wishlist_id);
    setTitle(targetWish.title || '');
    setDescription(targetWish.description || '');
    setUrl(targetWish.url || '');
    setPrice(targetWish.price !== undefined ? targetWish.price.toString() : '');
    setCurrency(targetWish.currency || 'USD');
    setImages(targetWish.images && targetWish.images.length > 0 ? targetWish.images.join(', ') : '');
    setPriority(targetWish.priority ? targetWish.priority.toString() : '3');
    setQuantity(targetWish.quantity ? targetWish.quantity.toString() : '1');
  };

  useEffect(() => {
    if (wish) {
      populateFormFromWish(wish);
    }
  }, [wish]);

  const fetchUserWishlists = async (showToast: boolean = false) => {
    if (!wish?.username) return;

    setIsWishlistsLoading(true);
    setWishlistsError('');

    try {
      const response = await fetch(
        `/api/proxy?endpoint=${encodeURIComponent(`/public/users/${wish.username}`)}`
      );
      const payload = await response.json().catch(() => ({}));

      if (!response.ok) {
        throw new Error(payload?.error?.message || 'Failed to load wishlists for this user.');
      }

      const nextWishlists = Array.isArray(payload?.wishlists) ? payload.wishlists : [];
      setWishlists(nextWishlists);

      if (nextWishlists.length > 0) {
        const exists = nextWishlists.find((wl: PublicWishlist) => wl.id === wishlistId);
        if (!exists) {
          setWishlistId(nextWishlists[0].id);
        }
      } else {
        setWishlistsError('User has no available wishlists.');
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load wishlists.';
      setWishlistsError(message);
      if (showToast) {
        toast.error('Unable to fetch wishlists', {
          description: message,
        });
      }
    } finally {
      setIsWishlistsLoading(false);
    }
  };

  useEffect(() => {
    fetchUserWishlists();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [wish?.username]);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!wishId || !wishlistId) {
      toast.error('Missing wishlist', {
        description: 'Please select a wishlist before saving.',
      });
      return;
    }

    setIsSaving(true);

    try {
      await updateWish(wishId, {
        username,
        wishlist_id: wishlistId,
        title,
        description: description || undefined,
        url: url || undefined,
        price: price ? parseFloat(price) : undefined,
        currency: currency || 'USD',
        images: images
          ? images
              .split(',')
              .map((imageUrl) => imageUrl.trim())
              .filter(Boolean)
          : undefined,
        priority: parseInt(priority, 10) || 3,
        quantity: parseInt(quantity, 10) || 1,
      });

      toast.success('Wish updated', {
        description: `"${title}" has been updated successfully.`,
      });
      await mutate();
    } catch (err: any) {
      const errorMessage = err?.message || 'Failed to update wish';
      const errorCode = err?.code || 'UNKNOWN_ERROR';
      const statusCode = err?.status || 'N/A';

      toast.error('Failed to update wish', {
        description: `${errorMessage}\n\nStatus: ${statusCode}\nCode: ${errorCode}`,
        duration: 8000,
      });
    } finally {
      setIsSaving(false);
    }
  };

  const handleReset = () => {
    if (wish) {
      populateFormFromWish(wish);
    }
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <Button variant="ghost" type="button" onClick={() => router.back()} className="px-0">
              <ArrowLeft className="h-4 w-4" />
              Back
            </Button>
            <div>
              <h1 className="text-3xl font-bold">Edit Wish</h1>
              {wish?.title && (
                <p className="text-gray-500 mt-1 line-clamp-1">{wish.title}</p>
              )}
            </div>
          </div>
          {wish?.username && (
            <div className="text-sm text-gray-500">
              Editing wish for <span className="font-semibold">@{wish.username}</span>
            </div>
          )}
        </div>

        {isLoading && (
          <Card>
            <CardHeader>
              <CardTitle>Loading wish details...</CardTitle>
              <CardDescription>Please wait while we fetch wish information.</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Loader2 className="h-4 w-4 animate-spin" />
                Loading
              </div>
            </CardContent>
          </Card>
        )}

        {error && !isLoading && (
          <Card>
            <CardHeader>
              <CardTitle>Failed to load wish</CardTitle>
              <CardDescription>
                We could not fetch the wish details. Please verify the ID or try again later.
              </CardDescription>
            </CardHeader>
          </Card>
        )}

        {!isLoading && !error && !wish && (
          <Card>
            <CardHeader>
              <CardTitle>Wish not found</CardTitle>
              <CardDescription>The requested wish could not be located.</CardDescription>
            </CardHeader>
          </Card>
        )}

        {wish && (
          <>
            <Card>
              <CardHeader>
                <CardTitle>Wish Information</CardTitle>
                <CardDescription>Update product details, metadata, and destination list.</CardDescription>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleSubmit} className="space-y-5">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="username">Username</Label>
                      <Input id="username" value={username} disabled readOnly />
                    </div>
                    <div className="space-y-2">
                      <div className="flex items-center justify-between gap-2">
                        <Label htmlFor="wishlist">Wishlist</Label>
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => fetchUserWishlists(true)}
                          disabled={isWishlistsLoading}
                          className="gap-2"
                        >
                          <RefreshCcw className={`h-4 w-4 ${isWishlistsLoading ? 'animate-spin' : ''}`} />
                          Refresh
                        </Button>
                      </div>
                      {wishlists.length > 0 ? (
                        <select
                          id="wishlist"
                          value={wishlistId}
                          onChange={(e) => setWishlistId(e.target.value)}
                          className="w-full px-3 py-2 border border-zinc-700 rounded-md bg-zinc-800 text-white"
                        >
                          {wishlists.map((wl) => (
                            <option key={wl.id} value={wl.id}>
                              {wl.name} {wl.visibility && `(${wl.visibility})`}
                            </option>
                          ))}
                        </select>
                      ) : (
                        <div className="text-sm text-muted-foreground border border-dashed rounded-md px-3 py-2">
                          {wishlistsError || 'No wishlists available for this user.'}
                        </div>
                      )}
                      {wishlistsError && (
                        <p className="text-sm text-destructive">{wishlistsError}</p>
                      )}
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="title">Title</Label>
                    <Input
                      id="title"
                      value={title}
                      onChange={(e) => setTitle(e.target.value)}
                      required
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="description">Description</Label>
                    <textarea
                      id="description"
                      value={description}
                      onChange={(e) => setDescription(e.target.value)}
                      rows={3}
                      className="w-full px-3 py-2 border border-zinc-700 rounded-md bg-zinc-800 text-white placeholder:text-zinc-400"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="url">Product URL</Label>
                    <Input
                      id="url"
                      type="url"
                      value={url}
                      onChange={(e) => setUrl(e.target.value)}
                      placeholder="https://example.com/product"
                    />
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="price">Price</Label>
                      <Input
                        id="price"
                        type="number"
                        placeholder="199.99"
                        value={price}
                        onChange={(e) => setPrice(e.target.value)}
                        min="0"
                        step="0.01"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="currency">Currency</Label>
                      <Input
                        id="currency"
                        value={currency}
                        onChange={(e) => setCurrency(e.target.value.toUpperCase())}
                        maxLength={3}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="priority">Priority (1-5)</Label>
                      <select
                        id="priority"
                        value={priority}
                        onChange={(e) => setPriority(e.target.value)}
                        className="w-full px-3 py-2 border border-zinc-700 rounded-md bg-zinc-800 text-white"
                      >
                        {[1, 2, 3, 4, 5].map((value) => (
                          <option key={value} value={value}>
                            {value}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="quantity">Quantity</Label>
                      <Input
                        id="quantity"
                        type="number"
                        min="1"
                        value={quantity}
                        onChange={(e) => setQuantity(e.target.value)}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="images">Image URLs</Label>
                      <textarea
                        id="images"
                        value={images}
                        onChange={(e) => setImages(e.target.value)}
                        rows={3}
                        className="w-full px-3 py-2 border border-zinc-700 rounded-md bg-zinc-800 text-white placeholder:text-zinc-400"
                        placeholder="https://example.com/img1.jpg, https://example.com/img2.jpg"
                      />
                      <p className="text-xs text-muted-foreground">
                        Separate multiple URLs with commas.
                      </p>
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-3">
                    <Button type="submit" disabled={isSaving || !title}>
                      {isSaving ? (
                        <>
                          <Loader2 className="h-4 w-4 animate-spin" />
                          Saving...
                        </>
                      ) : (
                        <>
                          <Save className="h-4 w-4" />
                          Save Changes
                        </>
                      )}
                    </Button>
                    <Button
                      type="button"
                      variant="outline"
                      onClick={handleReset}
                      disabled={isSaving}
                    >
                      Reset to Original
                    </Button>
                  </div>
                </form>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Metadata</CardTitle>
                <CardDescription>Useful context when working with support tickets.</CardDescription>
              </CardHeader>
              <CardContent>
                <dl className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                  <div>
                    <dt className="text-muted-foreground">Wish ID</dt>
                    <dd className="font-mono break-all">{wish.id}</dd>
                  </div>
                  <div>
                    <dt className="text-muted-foreground">Status</dt>
                    <dd className="capitalize font-medium">{wish.status}</dd>
                  </div>
                  <div>
                    <dt className="text-muted-foreground">Wishlist</dt>
                    <dd>{wish.wishlist_name || 'N/A'}</dd>
                  </div>
                  <div>
                    <dt className="text-muted-foreground">Added</dt>
                    <dd>{new Date(wish.added_at).toLocaleString()}</dd>
                  </div>
                  {wish.reserved_at && (
                    <div>
                      <dt className="text-muted-foreground">Reserved</dt>
                      <dd>{new Date(wish.reserved_at).toLocaleString()}</dd>
                    </div>
                  )}
                </dl>
              </CardContent>
            </Card>
          </>
        )}
      </div>
    </DashboardLayout>
  );
}


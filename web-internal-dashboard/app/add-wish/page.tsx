'use client';

import { useState, useEffect } from 'react';
import { DashboardLayout } from '@/components/dashboard-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { createWish, listUsers } from '@/lib/api';
import { Plus, Search, CheckCircle, User } from 'lucide-react';
import useSWR from 'swr';

export default function AddWishPage() {
  // Form state
  const [username, setUsername] = useState('');
  const [wishlistId, setWishlistId] = useState('');
  const [wishlists, setWishlists] = useState<any[]>([]);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [url, setUrl] = useState('');
  const [price, setPrice] = useState('');
  const [currency, setCurrency] = useState('USD');
  const [images, setImages] = useState('');
  const [priority, setPriority] = useState('3');
  const [quantity, setQuantity] = useState('1');

  // UI state
  const [isSearching, setIsSearching] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [userFound, setUserFound] = useState(false);

  // Fetch fake users list
  const { data: fakeUsersData } = useSWR(
    '/admin/users/list?fake_only=true&limit=100',
    () => listUsers({ fake_only: true, limit: 100 }),
    { refreshInterval: 30000 }
  );

  const selectFakeUser = (fakeUsername: string) => {
    setUsername(fakeUsername);
    searchUser(fakeUsername);
  };

  const searchUser = async (usernameToSearch?: string) => {
    const searchUsername = usernameToSearch || username;

    if (!searchUsername.trim()) {
      setError('Please enter a username');
      return;
    }

    setError('');
    setSuccess('');
    setIsSearching(true);
    setUserFound(false);
    setWishlists([]);
    setWishlistId('');

    try {
      // Fetch user's wishlists using public endpoint
      const response = await fetch(`/api/proxy?endpoint=${encodeURIComponent(`/users/${searchUsername}/wishlists`)}`);

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error?.message || 'User not found');
      }

      const data = await response.json();

      if (data.wishlists && data.wishlists.length > 0) {
        setWishlists(data.wishlists);
        setWishlistId(data.wishlists[0].id); // Auto-select first wishlist
        setUserFound(true);
      } else {
        setError('User has no wishlists');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to find user');
    } finally {
      setIsSearching(false);
    }
  };

  const handleCreateWish = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!wishlistId) {
      setError('Please select a wishlist');
      return;
    }

    setError('');
    setSuccess('');
    setIsCreating(true);

    try {
      await createWish({
        username,
        wishlist_id: wishlistId,
        title,
        description: description || undefined,
        url: url || undefined,
        price: price ? parseFloat(price) : undefined,
        currency: currency || 'USD',
        images: images ? images.split(',').map(url => url.trim()) : undefined,
        priority: parseInt(priority) || 3,
        quantity: parseInt(quantity) || 1,
      });

      setSuccess(`Wish "${title}" added successfully to @${username}'s wishlist!`);

      // Reset wish form (but keep user/wishlist selection)
      setTitle('');
      setDescription('');
      setUrl('');
      setPrice('');
      setCurrency('USD');
      setImages('');
      setPriority('3');
      setQuantity('1');

      // Clear success message after 3 seconds
      setTimeout(() => setSuccess(''), 3000);
    } catch (err: any) {
      setError(err.message || 'Failed to create wish');
    } finally {
      setIsCreating(false);
    }
  };

  const resetForm = () => {
    setUsername('');
    setWishlistId('');
    setWishlists([]);
    setTitle('');
    setDescription('');
    setUrl('');
    setPrice('');
    setCurrency('USD');
    setImages('');
    setPriority('3');
    setQuantity('1');
    setUserFound(false);
    setError('');
    setSuccess('');
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Page header */}
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Add Wish</h1>
          <p className="text-muted-foreground mt-1.5">
            Add a wish to any user's wishlist
          </p>
        </div>

        {/* Success/Error Messages */}
        {success && (
          <div className="bg-green-50 dark:bg-green-950 border border-green-200 dark:border-green-800 rounded-lg p-4 text-green-800 dark:text-green-200 flex items-center gap-2">
            <CheckCircle className="h-5 w-5" />
            {success}
          </div>
        )}

        {error && (
          <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-4 text-destructive">
            {error}
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left Column: User Search */}
          <div className="lg:col-span-2 space-y-6">
            {/* User Search */}
            <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Search className="h-5 w-5" />
              Find User
            </CardTitle>
            <CardDescription>
              Search for a user by username to add a wish to their wishlist
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex gap-3">
              <div className="flex-grow space-y-2">
                <Label htmlFor="username">Username</Label>
                <Input
                  id="username"
                  placeholder="johndoe"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && searchUser()}
                  disabled={userFound}
                />
              </div>
              <div className="flex items-end">
                {userFound ? (
                  <Button variant="outline" onClick={resetForm}>
                    Change User
                  </Button>
                ) : (
                  <Button onClick={() => searchUser()} disabled={isSearching}>
                    {isSearching ? 'Searching...' : 'Search'}
                  </Button>
                )}
              </div>
            </div>

            {/* Wishlist Selection */}
            {userFound && wishlists.length > 0 && (
              <div className="mt-4 space-y-2">
                <Label htmlFor="wishlist">Select Wishlist</Label>
                <select
                  id="wishlist"
                  value={wishlistId}
                  onChange={(e) => setWishlistId(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md"
                >
                  {wishlists.map((wl) => (
                    <option key={wl.id} value={wl.id}>
                      {wl.name} {wl.visibility && `(${wl.visibility})`}
                    </option>
                  ))}
                </select>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Wish Form */}
        {userFound && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Plus className="h-5 w-5" />
                Wish Details
              </CardTitle>
              <CardDescription>
                Fill in the wish information for @{username}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleCreateWish} className="space-y-4">
                {/* Title - Required */}
                <div className="space-y-2">
                  <Label htmlFor="title">
                    Title <span className="text-red-500">*</span>
                  </Label>
                  <Input
                    id="title"
                    placeholder="iPhone 15 Pro"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    required
                  />
                </div>

                {/* Description */}
                <div className="space-y-2">
                  <Label htmlFor="description">Description</Label>
                  <Input
                    id="description"
                    placeholder="Space Black, 256GB"
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                  />
                </div>

                {/* URL */}
                <div className="space-y-2">
                  <Label htmlFor="url">Product URL</Label>
                  <Input
                    id="url"
                    placeholder="https://www.apple.com/..."
                    value={url}
                    onChange={(e) => setUrl(e.target.value)}
                  />
                </div>

                {/* Price and Currency */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="price">Price</Label>
                    <Input
                      id="price"
                      type="number"
                      step="0.01"
                      placeholder="999.99"
                      value={price}
                      onChange={(e) => setPrice(e.target.value)}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="currency">Currency</Label>
                    <Input
                      id="currency"
                      placeholder="USD"
                      value={currency}
                      onChange={(e) => setCurrency(e.target.value)}
                    />
                  </div>
                </div>

                {/* Images */}
                <div className="space-y-2">
                  <Label htmlFor="images">Image URLs (comma-separated)</Label>
                  <Input
                    id="images"
                    placeholder="https://example.com/img1.jpg, https://example.com/img2.jpg"
                    value={images}
                    onChange={(e) => setImages(e.target.value)}
                  />
                </div>

                {/* Priority and Quantity */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="priority">Priority (1-5)</Label>
                    <Input
                      id="priority"
                      type="number"
                      min="1"
                      max="5"
                      value={priority}
                      onChange={(e) => setPriority(e.target.value)}
                    />
                  </div>
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
                </div>

                {/* Submit Button */}
                <div className="flex gap-3 pt-4">
                  <Button
                    type="submit"
                    disabled={isCreating || !title}
                    className="flex-1"
                  >
                    {isCreating ? 'Adding Wish...' : 'Add Wish'}
                  </Button>
                  <Button type="button" variant="outline" onClick={resetForm}>
                    Reset
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        )}
          </div>

          {/* Right Column: Fake Users List */}
          <div className="lg:col-span-1">
            <Card className="sticky top-6">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <User className="h-4 w-4" />
                  Fake Users
                </CardTitle>
                <CardDescription className="text-xs">
                  Click to select a test user
                </CardDescription>
              </CardHeader>
              <CardContent>
                {!fakeUsersData ? (
                  <div className="text-center py-8 text-sm text-muted-foreground">
                    Loading fake users...
                  </div>
                ) : fakeUsersData.users.length === 0 ? (
                  <div className="text-center py-8 text-sm text-muted-foreground">
                    No fake users found
                  </div>
                ) : (
                  <div className="space-y-1 max-h-[600px] overflow-y-auto">
                    {fakeUsersData.users.map((user) => (
                      <button
                        key={user.id}
                        onClick={() => selectFakeUser(user.username)}
                        disabled={isSearching}
                        className={`w-full text-left px-3 py-2 rounded-md text-sm transition-colors ${
                          username === user.username
                            ? 'bg-secondary text-secondary-foreground font-medium'
                            : 'hover:bg-secondary/50'
                        } ${isSearching ? 'opacity-50 cursor-not-allowed' : ''}`}
                      >
                        <div className="flex items-center gap-2">
                          <div className="h-8 w-8 rounded-full bg-muted flex items-center justify-center text-xs font-medium">
                            {user.username.slice(0, 2).toUpperCase()}
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="font-medium truncate">@{user.username}</p>
                            {user.full_name && (
                              <p className="text-xs text-muted-foreground truncate">
                                {user.full_name}
                              </p>
                            )}
                          </div>
                        </div>
                      </button>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}

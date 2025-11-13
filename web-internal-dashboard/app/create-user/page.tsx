'use client';

import { useState } from 'react';
import { DashboardLayout } from '@/components/dashboard-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { createUser, createWish } from '@/lib/api';
import { UserPlus, Plus, Trash2, CheckCircle } from 'lucide-react';

interface WishForm {
  id: string;
  title: string;
  description: string;
  url: string;
  price: string;
  currency: string;
  images: string;
  priority: string;
  quantity: string;
}

export default function CreateUserPage() {
  // User form state
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [fullName, setFullName] = useState('');
  const [avatarUrl, setAvatarUrl] = useState('');
  const [bio, setBio] = useState('');
  const [location, setLocation] = useState('');
  const [birthdate, setBirthdate] = useState('');
  const [gender, setGender] = useState('');

  // Wish forms state
  const [wishes, setWishes] = useState<WishForm[]>([]);
  const [showWishSection, setShowWishSection] = useState(false);

  // Created user state
  const [createdUser, setCreatedUser] = useState<any>(null);
  const [createdWishlist, setCreatedWishlist] = useState<any>(null);

  // UI state
  const [isCreatingUser, setIsCreatingUser] = useState(false);
  const [isCreatingWishes, setIsCreatingWishes] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const addWishForm = () => {
    setWishes([
      ...wishes,
      {
        id: Date.now().toString(),
        title: '',
        description: '',
        url: '',
        price: '',
        currency: 'USD',
        images: '',
        priority: '3',
        quantity: '1',
      },
    ]);
  };

  const removeWishForm = (id: string) => {
    setWishes(wishes.filter((w) => w.id !== id));
  };

  const updateWishForm = (id: string, field: keyof WishForm, value: string) => {
    setWishes(wishes.map((w) => (w.id === id ? { ...w, [field]: value } : w)));
  };

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setIsCreatingUser(true);

    try {
      const result = await createUser({
        username,
        email: email || undefined,
        full_name: fullName || undefined,
        avatar_url: avatarUrl || undefined,
        bio: bio || undefined,
        location: location || undefined,
        birthdate: birthdate || undefined,
        gender: gender || undefined,
      });

      setCreatedUser(result.user);
      setCreatedWishlist(result.wishlist);
      setSuccess(`User @${result.user.username} created successfully!`);
      setShowWishSection(true);
    } catch (err: any) {
      setError(err.message || 'Failed to create user');
    } finally {
      setIsCreatingUser(false);
    }
  };

  const handleCreateWishes = async () => {
    if (!createdUser || !createdWishlist) return;

    setError('');
    setIsCreatingWishes(true);

    try {
      const validWishes = wishes.filter((w) => w.title.trim());

      if (validWishes.length === 0) {
        setError('Please add at least one wish with a title');
        setIsCreatingWishes(false);
        return;
      }

      const createPromises = validWishes.map((wish) =>
        createWish({
          username: createdUser.username,
          wishlist_id: createdWishlist.id,
          title: wish.title,
          description: wish.description || undefined,
          url: wish.url || undefined,
          price: wish.price ? parseFloat(wish.price) : undefined,
          currency: wish.currency || 'USD',
          images: wish.images ? wish.images.split(',').map((url) => url.trim()) : undefined,
          priority: parseInt(wish.priority) || 3,
          quantity: parseInt(wish.quantity) || 1,
        })
      );

      await Promise.all(createPromises);

      setSuccess(
        `User @${createdUser.username} created with ${validWishes.length} wish(es)!`
      );

      // Reset form
      setTimeout(() => {
        resetForm();
      }, 2000);
    } catch (err: any) {
      setError(err.message || 'Failed to create wishes');
    } finally {
      setIsCreatingWishes(false);
    }
  };

  const resetForm = () => {
    setUsername('');
    setEmail('');
    setFullName('');
    setAvatarUrl('');
    setBio('');
    setLocation('');
    setBirthdate('');
    setGender('');
    setWishes([]);
    setCreatedUser(null);
    setCreatedWishlist(null);
    setShowWishSection(false);
    setSuccess('');
    setError('');
  };

  return (
    <DashboardLayout>
      <div className="space-y-6 max-w-4xl">
        {/* Page header */}
        <div>
          <h1 className="text-3xl font-bold">Create Fake User</h1>
          <p className="text-gray-500 mt-1">
            Create test users for development and testing purposes
          </p>
        </div>

        {/* Success/Error Messages */}
        {success && (
          <div className="bg-green-50 border border-green-200 rounded-lg p-4 text-green-800 flex items-center gap-2">
            <CheckCircle className="h-5 w-5" />
            {success}
          </div>
        )}

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
            {error}
          </div>
        )}

        {/* User Creation Form */}
        {!createdUser && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <UserPlus className="h-5 w-5" />
                User Information
              </CardTitle>
              <CardDescription>
                Fill in the user details. Only username is required.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleCreateUser} className="space-y-4">
                {/* Username - Required */}
                <div className="space-y-2">
                  <Label htmlFor="username">
                    Username <span className="text-red-500">*</span>
                  </Label>
                  <Input
                    id="username"
                    placeholder="johndoe"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    required
                  />
                </div>

                {/* Email */}
                <div className="space-y-2">
                  <Label htmlFor="email">Email</Label>
                  <Input
                    id="email"
                    type="email"
                    placeholder="john@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>

                {/* Full Name */}
                <div className="space-y-2">
                  <Label htmlFor="fullName">Full Name</Label>
                  <Input
                    id="fullName"
                    placeholder="John Doe"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                  />
                </div>

                {/* Avatar URL */}
                <div className="space-y-2">
                  <Label htmlFor="avatarUrl">Avatar URL</Label>
                  <Input
                    id="avatarUrl"
                    placeholder="https://example.com/avatar.jpg"
                    value={avatarUrl}
                    onChange={(e) => setAvatarUrl(e.target.value)}
                  />
                </div>

                {/* Bio */}
                <div className="space-y-2">
                  <Label htmlFor="bio">Bio</Label>
                  <Input
                    id="bio"
                    placeholder="A short bio about the user"
                    value={bio}
                    onChange={(e) => setBio(e.target.value)}
                  />
                </div>

                {/* Location */}
                <div className="space-y-2">
                  <Label htmlFor="location">Location</Label>
                  <Input
                    id="location"
                    placeholder="San Francisco, CA"
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                  />
                </div>

                {/* Grid for Birthdate and Gender */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {/* Birthdate */}
                  <div className="space-y-2">
                    <Label htmlFor="birthdate">Birthdate</Label>
                    <Input
                      id="birthdate"
                      type="date"
                      value={birthdate}
                      onChange={(e) => setBirthdate(e.target.value)}
                    />
                  </div>

                  {/* Gender */}
                  <div className="space-y-2">
                    <Label htmlFor="gender">Gender</Label>
                    <select
                      id="gender"
                      value={gender}
                      onChange={(e) => setGender(e.target.value)}
                      className="w-full px-3 py-2 border border-zinc-700 rounded-md bg-zinc-800 text-white"
                    >
                      <option value="">Select gender</option>
                      <option value="male">Male</option>
                      <option value="female">Female</option>
                      <option value="other">Other</option>
                      <option value="prefer_not_to_say">Prefer not to say</option>
                    </select>
                  </div>
                </div>

                {/* Submit Button */}
                <Button
                  type="submit"
                  disabled={isCreatingUser || !username}
                  className="w-full"
                >
                  {isCreatingUser ? 'Creating User...' : 'Create User'}
                </Button>
              </form>
            </CardContent>
          </Card>
        )}

        {/* Wishes Section */}
        {showWishSection && createdUser && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Plus className="h-5 w-5" />
                Add Wishes (Optional)
              </CardTitle>
              <CardDescription>
                Add wishes to {createdUser.username}'s default wishlist "{createdWishlist.name}"
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {wishes.map((wish, index) => (
                <div key={wish.id} className="border rounded-lg p-4 space-y-3">
                  <div className="flex items-center justify-between">
                    <h4 className="font-semibold">Wish #{index + 1}</h4>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => removeWishForm(wish.id)}
                    >
                      <Trash2 className="h-4 w-4 text-red-500" />
                    </Button>
                  </div>

                  {/* Title - Required */}
                  <div className="space-y-2">
                    <Label>
                      Title <span className="text-red-500">*</span>
                    </Label>
                    <Input
                      placeholder="iPhone 15 Pro"
                      value={wish.title}
                      onChange={(e) => updateWishForm(wish.id, 'title', e.target.value)}
                    />
                  </div>

                  {/* Description */}
                  <div className="space-y-2">
                    <Label>Description</Label>
                    <Input
                      placeholder="Space Black, 256GB"
                      value={wish.description}
                      onChange={(e) => updateWishForm(wish.id, 'description', e.target.value)}
                    />
                  </div>

                  {/* URL */}
                  <div className="space-y-2">
                    <Label>Product URL</Label>
                    <Input
                      placeholder="https://www.apple.com/..."
                      value={wish.url}
                      onChange={(e) => updateWishForm(wish.id, 'url', e.target.value)}
                    />
                  </div>

                  {/* Price and Currency */}
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label>Price</Label>
                      <Input
                        type="number"
                        step="0.01"
                        placeholder="999.99"
                        value={wish.price}
                        onChange={(e) => updateWishForm(wish.id, 'price', e.target.value)}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label>Currency</Label>
                      <Input
                        placeholder="USD"
                        value={wish.currency}
                        onChange={(e) => updateWishForm(wish.id, 'currency', e.target.value)}
                      />
                    </div>
                  </div>

                  {/* Images */}
                  <div className="space-y-2">
                    <Label>Image URLs (comma-separated)</Label>
                    <Input
                      placeholder="https://example.com/img1.jpg, https://example.com/img2.jpg"
                      value={wish.images}
                      onChange={(e) => updateWishForm(wish.id, 'images', e.target.value)}
                    />
                  </div>

                  {/* Priority and Quantity */}
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label>Priority (1-5)</Label>
                      <Input
                        type="number"
                        min="1"
                        max="5"
                        value={wish.priority}
                        onChange={(e) => updateWishForm(wish.id, 'priority', e.target.value)}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label>Quantity</Label>
                      <Input
                        type="number"
                        min="1"
                        value={wish.quantity}
                        onChange={(e) => updateWishForm(wish.id, 'quantity', e.target.value)}
                      />
                    </div>
                  </div>
                </div>
              ))}

              {/* Add Wish Button */}
              <Button variant="outline" onClick={addWishForm} className="w-full">
                <Plus className="h-4 w-4 mr-2" />
                Add Another Wish
              </Button>

              {/* Action Buttons */}
              <div className="flex gap-3 pt-4">
                <Button
                  onClick={handleCreateWishes}
                  disabled={isCreatingWishes || wishes.length === 0}
                  className="flex-1"
                >
                  {isCreatingWishes ? 'Creating Wishes...' : `Create ${wishes.length} Wish(es)`}
                </Button>
                <Button variant="outline" onClick={resetForm}>
                  Skip & Finish
                </Button>
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </DashboardLayout>
  );
}

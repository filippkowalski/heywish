'use client';

export const runtime = 'edge';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { DashboardLayout } from '@/components/dashboard-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { listUsers, updateUser, deleteUser, type User } from '@/lib/api';
import { Edit, Trash2, CheckCircle, ArrowLeft } from 'lucide-react';
import Link from 'next/link';

export default function EditUserPage() {
  const params = useParams();
  const router = useRouter();
  const userId = params.id as string;

  // User form state
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [fullName, setFullName] = useState('');
  const [avatarUrl, setAvatarUrl] = useState('');
  const [bio, setBio] = useState('');
  const [location, setLocation] = useState('');
  const [birthdate, setBirthdate] = useState('');
  const [gender, setGender] = useState('');

  // UI state
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [user, setUser] = useState<User | null>(null);

  // Load user data
  useEffect(() => {
    loadUserData();
  }, [userId]);

  const loadUserData = async () => {
    setIsLoading(true);
    setError('');

    try {
      // We'll fetch all users and find the one we need
      // In a production app, you'd have a dedicated endpoint for fetching a single user
      // Try fetching from all users (real users)
      let response = await listUsers({ page: 1, limit: 1000 });
      let foundUser = response.users.find(u => u.id === userId);

      // If not found in real users, try fake users
      if (!foundUser) {
        response = await listUsers({ page: 1, limit: 1000, fake_only: true });
        foundUser = response.users.find(u => u.id === userId);
      }

      if (!foundUser) {
        setError('User not found');
        return;
      }

      setUser(foundUser);
      setUsername(foundUser.username || '');
      setEmail(foundUser.email || '');
      setFullName(foundUser.full_name || '');
      setAvatarUrl(foundUser.avatar_url || '');
      setBio(foundUser.bio || '');
      setLocation(foundUser.location || '');
      setBirthdate(foundUser.birthdate ? foundUser.birthdate.split('T')[0] : '');
      setGender(foundUser.gender || '');
    } catch (err: any) {
      setError(err.message || 'Failed to load user data');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSaveUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setIsSaving(true);

    try {
      const result = await updateUser(userId, {
        username: username !== user?.username ? username : undefined,
        email: email || undefined,
        full_name: fullName || undefined,
        avatar_url: avatarUrl || undefined,
        bio: bio || undefined,
        location: location || undefined,
        birthdate: birthdate || undefined,
        gender: gender || undefined,
      });

      setUser(result.user);
      setSuccess('User updated successfully!');

      // Refresh the form with updated data
      setTimeout(() => {
        setSuccess('');
      }, 3000);
    } catch (err: any) {
      setError(err.message || 'Failed to update user');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeleteUser = async () => {
    setError('');
    setIsDeleting(true);

    try {
      await deleteUser(userId);
      setSuccess('User deleted successfully!');

      // Redirect to users list after a short delay
      setTimeout(() => {
        router.push('/users');
      }, 1500);
    } catch (err: any) {
      setError(err.message || 'Failed to delete user');
      setIsDeleting(false);
      setShowDeleteConfirm(false);
    }
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="text-center py-12">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
          <p className="mt-4 text-gray-600">Loading user data...</p>
        </div>
      </DashboardLayout>
    );
  }

  if (!user && !isLoading) {
    return (
      <DashboardLayout>
        <div className="space-y-6 max-w-4xl">
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
            {error || 'User not found'}
          </div>
          <Link href="/users">
            <Button variant="outline">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Users
            </Button>
          </Link>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="space-y-6 max-w-4xl">
        {/* Page header */}
        <div className="flex items-center justify-between">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <Link href="/users">
                <Button variant="ghost" size="sm">
                  <ArrowLeft className="h-4 w-4 mr-1" />
                  Back
                </Button>
              </Link>
            </div>
            <h1 className="text-3xl font-bold">Edit User</h1>
            <p className="text-gray-500 mt-1">
              Editing @{user?.username}
              {user?.is_fake && (
                <span className="ml-2 px-2 py-0.5 text-xs font-medium bg-orange-100 text-orange-800 rounded">
                  Fake User
                </span>
              )}
            </p>
          </div>
          <Button
            variant="destructive"
            onClick={() => setShowDeleteConfirm(true)}
            disabled={isDeleting}
          >
            <Trash2 className="h-4 w-4 mr-2" />
            Delete User
          </Button>
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

        {/* Delete Confirmation */}
        {showDeleteConfirm && (
          <Card className="border-red-200 bg-red-50">
            <CardHeader>
              <CardTitle className="text-red-800">Confirm Deletion</CardTitle>
              <CardDescription>
                Are you sure you want to delete @{user?.username}? This action cannot be undone.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex gap-3">
                <Button
                  variant="destructive"
                  onClick={handleDeleteUser}
                  disabled={isDeleting}
                >
                  {isDeleting ? 'Deleting...' : 'Yes, Delete User'}
                </Button>
                <Button
                  variant="outline"
                  onClick={() => setShowDeleteConfirm(false)}
                  disabled={isDeleting}
                >
                  Cancel
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        {/* User Edit Form */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Edit className="h-5 w-5" />
              User Information
            </CardTitle>
            <CardDescription>
              Update the user details below.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSaveUser} className="space-y-4">
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
                {avatarUrl && (
                  <div className="mt-2">
                    <img
                      src={avatarUrl}
                      alt="Avatar preview"
                      className="w-16 h-16 rounded-full object-cover"
                      onError={(e) => {
                        (e.target as HTMLImageElement).style.display = 'none';
                      }}
                    />
                  </div>
                )}
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
                    className="w-full px-3 py-2 border border-gray-300 rounded-md"
                  >
                    <option value="">Select gender</option>
                    <option value="male">Male</option>
                    <option value="female">Female</option>
                    <option value="other">Other</option>
                    <option value="prefer_not_to_say">Prefer not to say</option>
                  </select>
                </div>
              </div>

              {/* Metadata (Read-only) */}
              <div className="pt-4 border-t">
                <h3 className="font-semibold mb-3">Metadata</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-gray-600">
                  <div>
                    <span className="font-medium">User ID:</span> {user?.id}
                  </div>
                  <div>
                    <span className="font-medium">Firebase UID:</span> {user?.firebase_uid}
                  </div>
                  <div>
                    <span className="font-medium">Sign-up Method:</span>{' '}
                    <span className="capitalize">{user?.sign_up_method || 'unknown'}</span>
                  </div>
                  <div>
                    <span className="font-medium">Created:</span>{' '}
                    {user?.created_at ? new Date(user.created_at).toLocaleString() : 'N/A'}
                  </div>
                  <div>
                    <span className="font-medium">Updated:</span>{' '}
                    {user?.updated_at ? new Date(user.updated_at).toLocaleString() : 'N/A'}
                  </div>
                  <div>
                    <span className="font-medium">Fake User:</span>{' '}
                    {user?.is_fake ? 'Yes' : 'No'}
                  </div>
                </div>
              </div>

              {/* Submit Button */}
              <Button
                type="submit"
                disabled={isSaving || !username}
                className="w-full"
              >
                {isSaving ? 'Saving Changes...' : 'Save Changes'}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
}

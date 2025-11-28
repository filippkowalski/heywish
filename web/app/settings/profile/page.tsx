'use client';

import { useAuth } from '@/lib/auth/AuthContext.client';
import { useRouter } from 'next/navigation';
import { useEffect, useState, useRef } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Loader2, Camera, CheckCircle2, XCircle, AlertCircle } from 'lucide-react';
import { toast } from 'sonner';

export const runtime = 'edge';

type UsernameStatus = 'idle' | 'checking' | 'available' | 'taken' | 'error' | 'invalid';

export default function EditProfilePage() {
  const { user, backendUser, loading, getIdToken, refreshUser } = useAuth();
  const router = useRouter();

  const [fullName, setFullName] = useState('');
  const [username, setUsername] = useState('');
  const [bio, setBio] = useState('');
  const [avatarUrl, setAvatarUrl] = useState('');
  const [selectedImage, setSelectedImage] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

  const [usernameStatus, setUsernameStatus] = useState<UsernameStatus>('idle');
  const [isSaving, setIsSaving] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const usernameCheckTimeout = useRef<NodeJS.Timeout | null>(null);

  const originalUsername = useRef('');

  // Initialize form with user data
  useEffect(() => {
    if (backendUser) {
      setFullName(backendUser.full_name || '');
      setUsername(backendUser.username || '');
      originalUsername.current = backendUser.username || '';
      setBio(backendUser.bio || '');
      setAvatarUrl(backendUser.avatar_url || '');
    }
  }, [backendUser]);

  // Redirect if not authenticated
  useEffect(() => {
    if (!loading && !user) {
      router.push('/');
    }
  }, [user, loading, router]);

  // Username validation
  const validateUsername = (value: string): boolean => {
    if (value.length < 3 || value.length > 30) return false;
    if (value.includes(' ')) return false;
    if (!/^[a-zA-Z0-9._]+$/.test(value)) return false;
    if (value.startsWith('.') || value.endsWith('.')) return false;
    if (/\.\./.test(value)) return false;
    return true;
  };

  // Check username availability
  const checkUsernameAvailability = async (value: string) => {
    try {
      const token = await getIdToken();
      if (!token) return;

      const response = await fetch(
        `https://openai-rewrite.onrender.com/jinnie/v1/auth/check-username/${encodeURIComponent(value)}`,
        {
          headers: {
            'Authorization': `Bearer ${token}`,
          },
        }
      );

      if (!response.ok) {
        setUsernameStatus('error');
        return;
      }

      const data = await response.json();
      setUsernameStatus(data.available ? 'available' : 'taken');
    } catch (error) {
      console.error('Username check error:', error);
      setUsernameStatus('error');
    }
  };

  // Handle username change with debounce
  const handleUsernameChange = (value: string) => {
    // Clean the input
    const cleaned = value.toLowerCase().replace(/\s/g, '');
    setUsername(cleaned);

    // Clear existing timeout
    if (usernameCheckTimeout.current) {
      clearTimeout(usernameCheckTimeout.current);
    }

    // If username hasn't changed, don't check
    if (cleaned === originalUsername.current) {
      setUsernameStatus('idle');
      return;
    }

    // Validate format
    if (!validateUsername(cleaned)) {
      setUsernameStatus('invalid');
      return;
    }

    // Check availability after 500ms
    setUsernameStatus('checking');
    usernameCheckTimeout.current = setTimeout(() => {
      checkUsernameAvailability(cleaned);
    }, 500);
  };

  // Handle image selection
  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setSelectedImage(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreviewUrl(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  // Upload avatar to R2
  const uploadAvatar = async (file: File): Promise<string> => {
    const token = await getIdToken();
    if (!token) throw new Error('Not authenticated');

    // Get presigned URL
    const response = await fetch('https://openai-rewrite.onrender.com/jinnie/v1/upload/avatar', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        fileExtension: file.name.split('.').pop() || 'jpg',
        contentType: file.type,
      }),
    });

    if (!response.ok) {
      throw new Error('Failed to get upload URL');
    }

    const { uploadUrl, publicUrl } = await response.json();

    // Upload to R2
    const uploadResponse = await fetch(uploadUrl, {
      method: 'PUT',
      headers: {
        'Content-Type': file.type,
      },
      body: file,
    });

    if (!uploadResponse.ok) {
      throw new Error('Failed to upload image');
    }

    return publicUrl;
  };

  // Save profile
  const handleSave = async () => {
    setIsSaving(true);
    try {
      const token = await getIdToken();
      if (!token) {
        throw new Error('Not authenticated');
      }

      // Upload avatar if changed
      let newAvatarUrl = avatarUrl;
      if (selectedImage) {
        newAvatarUrl = await uploadAvatar(selectedImage);
      }

      // Build update payload
      const updateData: Record<string, string> = {};
      if (fullName !== backendUser?.full_name) {
        updateData.full_name = fullName;
      }
      if (username !== originalUsername.current) {
        updateData.username = username;
      }
      if (bio !== backendUser?.bio) {
        updateData.bio = bio;
      }
      if (newAvatarUrl !== avatarUrl) {
        updateData.avatar_url = newAvatarUrl;
      }

      // Update profile
      const response = await fetch('https://openai-rewrite.onrender.com/jinnie/v1/users/profile', {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(updateData),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to update profile');
      }

      // Refresh user data
      await refreshUser();

      toast.success('Profile updated successfully');
      router.push('/settings');
    } catch (error) {
      console.error('Save profile error:', error);
      toast.error(error instanceof Error ? error.message : 'Failed to update profile');
    } finally {
      setIsSaving(false);
    }
  };

  // Check if form is valid and changed
  const isFormValid = () => {
    if (!fullName.trim()) return false;
    if (username !== originalUsername.current) {
      if (!validateUsername(username)) return false;
      if (usernameStatus !== 'available') return false;
    }
    return true;
  };

  const hasChanges = () => {
    return (
      fullName !== (backendUser?.full_name || '') ||
      username !== originalUsername.current ||
      bio !== (backendUser?.bio || '') ||
      selectedImage !== null
    );
  };

  const canSave = isFormValid() && hasChanges() && !isSaving;

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (!user) {
    return null;
  }

  const getUserInitials = (name?: string | null) => {
    if (name) {
      return name
        .split(' ')
        .map((n) => n[0])
        .join('')
        .toUpperCase()
        .slice(0, 2);
    }
    return 'U';
  };

  return (
    <div className="container max-w-2xl mx-auto px-4 py-8">
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Edit Profile</h1>
          <p className="text-muted-foreground mt-2">
            Update your profile information
          </p>
        </div>

        {/* Form */}
        <div className="bg-white rounded-lg border p-6 space-y-6">
          {/* Avatar */}
          <div className="flex flex-col items-center gap-4">
            <Avatar className="h-24 w-24">
              <AvatarImage src={previewUrl || avatarUrl || undefined} />
              <AvatarFallback>{getUserInitials(fullName)}</AvatarFallback>
            </Avatar>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => fileInputRef.current?.click()}
            >
              <Camera className="h-4 w-4 mr-2" />
              Change Photo
            </Button>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={handleImageSelect}
            />
          </div>

          {/* Full Name */}
          <div className="space-y-2">
            <Label htmlFor="fullName">Full Name *</Label>
            <Input
              id="fullName"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder="Enter your full name"
            />
          </div>

          {/* Username */}
          <div className="space-y-2">
            <Label htmlFor="username">Username *</Label>
            <div className="relative">
              <Input
                id="username"
                value={username}
                onChange={(e) => handleUsernameChange(e.target.value)}
                placeholder="Enter username"
                className="pr-10"
              />
              <div className="absolute right-3 top-1/2 -translate-y-1/2">
                {username !== originalUsername.current && (
                  <>
                    {usernameStatus === 'checking' && (
                      <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
                    )}
                    {usernameStatus === 'available' && (
                      <CheckCircle2 className="h-4 w-4 text-green-600" />
                    )}
                    {usernameStatus === 'taken' && (
                      <XCircle className="h-4 w-4 text-red-600" />
                    )}
                    {(usernameStatus === 'invalid' || usernameStatus === 'error') && (
                      <AlertCircle className="h-4 w-4 text-amber-600" />
                    )}
                  </>
                )}
              </div>
            </div>
            {username !== originalUsername.current && (
              <p className="text-sm text-muted-foreground">
                {usernameStatus === 'checking' && 'Checking availability...'}
                {usernameStatus === 'available' && 'Username is available'}
                {usernameStatus === 'taken' && 'Username is already taken'}
                {usernameStatus === 'invalid' && 'Username must be 3-30 characters, alphanumeric with . or _'}
                {usernameStatus === 'error' && 'Error checking username'}
              </p>
            )}
          </div>

          {/* Bio */}
          <div className="space-y-2">
            <Label htmlFor="bio">Bio</Label>
            <Textarea
              id="bio"
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              placeholder="Tell us about yourself"
              rows={4}
              maxLength={500}
            />
            <p className="text-sm text-muted-foreground text-right">
              {bio.length}/500
            </p>
          </div>
        </div>

        {/* Actions */}
        <div className="flex gap-3">
          <Button
            variant="outline"
            onClick={() => router.push('/settings')}
            disabled={isSaving}
            className="flex-1"
          >
            Cancel
          </Button>
          <Button
            onClick={handleSave}
            disabled={!canSave}
            className="flex-1"
          >
            {isSaving ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Saving...
              </>
            ) : (
              'Save Changes'
            )}
          </Button>
        </div>
      </div>
    </div>
  );
}

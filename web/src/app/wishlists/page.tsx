'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/contexts/AuthContext';
import Navigation from '@/components/Navigation';

interface Wishlist {
  id: string;
  name: string;
  description: string;
  item_count: number;
  reserved_count: number;
  visibility: string;
  occasion_type: string;
  event_date: string;
  created_at: string;
  share_token: string;
}

export default function WishlistsPage() {
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();
  const [wishlists, setWishlists] = useState<Wishlist[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!authLoading && user) {
      fetchWishlists();
    }
  }, [user, authLoading]);

  const fetchWishlists = async () => {
    try {
      const token = await user?.getIdToken();
      const response = await fetch('/api/wishlists', {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error('Failed to fetch wishlists');
      }

      const data = await response.json();
      setWishlists(data.wishlists);
    } catch (err: any) {
      setError(err.message || 'Failed to load wishlists');
    } finally {
      setLoading(false);
    }
  };

  const deleteWishlist = async (id: string) => {
    if (!confirm('Are you sure you want to delete this wishlist?')) {
      return;
    }

    try {
      const token = await user?.getIdToken();
      const response = await fetch(`/api/wishlists/${id}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error('Failed to delete wishlist');
      }

      setWishlists(wishlists.filter(w => w.id !== id));
    } catch (err: any) {
      setError(err.message || 'Failed to delete wishlist');
    }
  };

  const copyShareLink = (token: string) => {
    const url = `${window.location.origin}/shared/${token}`;
    navigator.clipboard.writeText(url);
    alert('Share link copied to clipboard!');
  };

  if (authLoading || loading) {
    return (
      <>
        <Navigation />
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Loading...</p>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <Navigation />
      <div className="min-h-screen bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {/* Header */}
          <div className="mb-8 flex justify-between items-center">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">My Wishlists</h1>
              <p className="mt-2 text-gray-600">Create and manage your wishlists</p>
            </div>
            <Link
              href="/wishlists/new"
              className="bg-purple-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-purple-700 transition"
            >
              Create New Wishlist
            </Link>
          </div>

          {error && (
            <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
              {error}
            </div>
          )}

          {wishlists.length === 0 ? (
            <div className="bg-white rounded-lg shadow-lg p-12 text-center">
              <svg className="mx-auto h-24 w-24 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7" />
              </svg>
              <h3 className="mt-4 text-lg font-medium text-gray-900">No wishlists yet</h3>
              <p className="mt-2 text-gray-500">Start creating your first wishlist to save and share your favorite items.</p>
              <div className="mt-6">
                <Link
                  href="/wishlists/new"
                  className="inline-flex items-center px-6 py-3 border border-transparent shadow-sm text-base font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700"
                >
                  Create Your First Wishlist
                </Link>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {wishlists.map((wishlist) => (
                <div key={wishlist.id} className="bg-white rounded-lg shadow-lg overflow-hidden">
                  <div className="p-6">
                    <div className="flex justify-between items-start mb-4">
                      <h3 className="text-xl font-semibold text-gray-900">{wishlist.name}</h3>
                      <span className={`px-3 py-1 text-xs font-medium rounded-full ${
                        wishlist.visibility === 'public' 
                          ? 'bg-green-100 text-green-800'
                          : wishlist.visibility === 'friends'
                          ? 'bg-blue-100 text-blue-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}>
                        {wishlist.visibility}
                      </span>
                    </div>

                    {wishlist.description && (
                      <p className="text-gray-600 mb-4 line-clamp-2">
                        {wishlist.description}
                      </p>
                    )}

                    {wishlist.occasion_type && (
                      <p className="text-sm text-gray-500 mb-2">
                        <span className="font-medium">Occasion:</span> {wishlist.occasion_type}
                      </p>
                    )}

                    {wishlist.event_date && (
                      <p className="text-sm text-gray-500 mb-4">
                        <span className="font-medium">Date:</span> {new Date(wishlist.event_date).toLocaleDateString()}
                      </p>
                    )}

                    <div className="flex justify-between items-center mb-4 pb-4 border-b">
                      <div className="flex space-x-4 text-sm text-gray-500">
                        <span>{wishlist.item_count || 0} items</span>
                        {wishlist.reserved_count > 0 && (
                          <span className="text-green-600 font-medium">{wishlist.reserved_count} reserved</span>
                        )}
                      </div>
                    </div>

                    <div className="flex space-x-2">
                      <Link
                        href={`/wishlists/${wishlist.id}`}
                        className="flex-1 text-center px-4 py-2 bg-purple-600 text-white rounded hover:bg-purple-700 transition"
                      >
                        View
                      </Link>
                      <Link
                        href={`/wishlists/${wishlist.id}/edit`}
                        className="flex-1 text-center px-4 py-2 bg-gray-200 text-gray-700 rounded hover:bg-gray-300 transition"
                      >
                        Edit
                      </Link>
                      <button
                        onClick={() => copyShareLink(wishlist.share_token)}
                        className="px-4 py-2 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition"
                        title="Copy share link"
                      >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m9.032 4.024A9.003 9.003 0 0112 3a9.003 9.003 0 012 18 9.003 9.003 0 01-5.716-2.318m11.432 0A9.003 9.003 0 0112 3a9.003 9.003 0 00-5.716 2.318m11.432 13.364A9.003 9.003 0 0112 21a9.003 9.003 0 01-5.716-2.318m11.432 0L21 21m-3.284-2.318l3.284 3.284" />
                        </svg>
                      </button>
                      <button
                        onClick={() => deleteWishlist(wishlist.id)}
                        className="px-4 py-2 bg-red-100 text-red-700 rounded hover:bg-red-200 transition"
                        title="Delete wishlist"
                      >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </>
  );
}
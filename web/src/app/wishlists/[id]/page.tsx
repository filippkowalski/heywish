'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/contexts/AuthContext';
import Navigation from '@/components/Navigation';
import Image from 'next/image';

interface WishItem {
  id: string;
  title: string;
  description: string;
  url: string;
  price: number;
  currency: string;
  images: string[];
  status: string;
  priority: number;
  quantity: number;
  notes: string;
  reserved_by: string;
  reserved_by_username: string;
  reserved_by_name: string;
}

interface Wishlist {
  id: string;
  name: string;
  description: string;
  visibility: string;
  occasion_type: string;
  event_date: string;
  share_token: string;
  items: WishItem[];
}

export default function WishlistDetailPage() {
  const router = useRouter();
  const params = useParams();
  const { user } = useAuth();
  const [wishlist, setWishlist] = useState<Wishlist | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);

  useEffect(() => {
    if (user && params.id) {
      fetchWishlist();
    }
  }, [user, params.id]);

  const fetchWishlist = async () => {
    try {
      const token = await user?.getIdToken();
      const response = await fetch(`/api/wishlists/${params.id}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error('Failed to fetch wishlist');
      }

      const data = await response.json();
      setWishlist(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load wishlist');
    } finally {
      setLoading(false);
    }
  };

  const deleteWish = async (wishId: string) => {
    if (!confirm('Are you sure you want to remove this item?')) {
      return;
    }

    try {
      const token = await user?.getIdToken();
      const response = await fetch(`/api/wishes/${wishId}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error('Failed to delete item');
      }

      // Refresh wishlist
      fetchWishlist();
    } catch (err: any) {
      setError(err.message || 'Failed to delete item');
    }
  };

  const copyShareLink = () => {
    const url = `${window.location.origin}/shared/${wishlist?.share_token}`;
    navigator.clipboard.writeText(url);
    alert('Share link copied to clipboard!');
  };

  if (loading) {
    return (
      <>
        <Navigation />
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Loading wishlist...</p>
          </div>
        </div>
      </>
    );
  }

  if (!wishlist) {
    return (
      <>
        <Navigation />
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="text-center">
            <p className="text-gray-600">Wishlist not found</p>
            <Link href="/wishlists" className="mt-4 text-purple-600 hover:text-purple-700">
              Back to wishlists
            </Link>
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
          <div className="bg-white rounded-lg shadow-lg p-6 mb-8">
            <div className="flex justify-between items-start mb-4">
              <div>
                <h1 className="text-3xl font-bold text-gray-900">{wishlist.name}</h1>
                {wishlist.description && (
                  <p className="mt-2 text-gray-600">{wishlist.description}</p>
                )}
                <div className="mt-4 flex flex-wrap gap-2">
                  <span className={`px-3 py-1 text-sm font-medium rounded-full ${
                    wishlist.visibility === 'public' 
                      ? 'bg-green-100 text-green-800'
                      : wishlist.visibility === 'friends'
                      ? 'bg-blue-100 text-blue-800'
                      : 'bg-gray-100 text-gray-800'
                  }`}>
                    {wishlist.visibility}
                  </span>
                  {wishlist.occasion_type && (
                    <span className="px-3 py-1 text-sm bg-purple-100 text-purple-800 rounded-full">
                      {wishlist.occasion_type}
                    </span>
                  )}
                  {wishlist.event_date && (
                    <span className="px-3 py-1 text-sm bg-gray-100 text-gray-800 rounded-full">
                      {new Date(wishlist.event_date).toLocaleDateString()}
                    </span>
                  )}
                </div>
              </div>
              <div className="flex space-x-2">
                <button
                  onClick={copyShareLink}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition"
                >
                  Share
                </button>
                <Link
                  href={`/wishlists/${wishlist.id}/edit`}
                  className="px-4 py-2 bg-gray-200 text-gray-700 rounded hover:bg-gray-300 transition"
                >
                  Edit
                </Link>
              </div>
            </div>
          </div>

          {/* Add Item Button */}
          <div className="mb-6 flex justify-between items-center">
            <h2 className="text-xl font-semibold text-gray-900">
              Items ({wishlist.items?.length || 0})
            </h2>
            <button
              onClick={() => setShowAddForm(true)}
              className="bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700 transition"
            >
              Add Item
            </button>
          </div>

          {error && (
            <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
              {error}
            </div>
          )}

          {/* Items Grid */}
          {wishlist.items?.length === 0 ? (
            <div className="bg-white rounded-lg shadow p-12 text-center">
              <svg className="mx-auto h-24 w-24 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7" />
              </svg>
              <h3 className="mt-4 text-lg font-medium text-gray-900">No items yet</h3>
              <p className="mt-2 text-gray-500">Start adding items to your wishlist</p>
              <button
                onClick={() => setShowAddForm(true)}
                className="mt-6 inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700"
              >
                Add Your First Item
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {wishlist.items.map((item) => (
                <div key={item.id} className="bg-white rounded-lg shadow-lg overflow-hidden">
                  {item.images && item.images.length > 0 && (
                    <div className="h-48 bg-gray-200 relative">
                      <img
                        src={item.images[0]}
                        alt={item.title}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          (e.target as HTMLImageElement).style.display = 'none';
                        }}
                      />
                    </div>
                  )}
                  <div className="p-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-2">{item.title}</h3>
                    {item.description && (
                      <p className="text-gray-600 text-sm mb-4 line-clamp-2">{item.description}</p>
                    )}
                    {item.price && (
                      <p className="text-2xl font-bold text-purple-600 mb-4">
                        ${item.price.toFixed(2)} {item.currency}
                      </p>
                    )}
                    {item.notes && (
                      <p className="text-sm text-gray-500 mb-4">{item.notes}</p>
                    )}
                    
                    {item.status === 'reserved' && (
                      <div className="mb-4 px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm text-center">
                        Reserved{item.reserved_by_name && ` by ${item.reserved_by_name}`}
                      </div>
                    )}

                    <div className="flex space-x-2">
                      {item.url && (
                        <a
                          href={item.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex-1 text-center px-3 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition text-sm"
                        >
                          View Item
                        </a>
                      )}
                      <button
                        onClick={() => deleteWish(item.id)}
                        className="px-3 py-2 bg-red-100 text-red-700 rounded hover:bg-red-200 transition"
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

      {/* Add Item Modal */}
      {showAddForm && (
        <AddWishModal
          wishlistId={wishlist.id}
          onClose={() => setShowAddForm(false)}
          onSuccess={() => {
            setShowAddForm(false);
            fetchWishlist();
          }}
        />
      )}
    </>
  );
}

// Add Wish Modal Component
function AddWishModal({ 
  wishlistId, 
  onClose, 
  onSuccess 
}: { 
  wishlistId: string; 
  onClose: () => void; 
  onSuccess: () => void;
}) {
  const { user } = useAuth();
  const [loading, setLoading] = useState(false);
  const [scraping, setScraping] = useState(false);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState({
    url: '',
    title: '',
    description: '',
    price: '',
    notes: '',
    priority: 5,
    quantity: 1,
  });

  const handleScrape = async () => {
    if (!formData.url) return;
    
    setScraping(true);
    setError('');

    try {
      const token = await user?.getIdToken();
      const response = await fetch('/api/scrape', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ url: formData.url }),
      });

      if (!response.ok) {
        throw new Error('Failed to scrape product');
      }

      const { product } = await response.json();
      setFormData({
        ...formData,
        title: product.title || formData.title,
        description: product.description || formData.description,
        price: product.price?.toString() || formData.price,
      });
    } catch (err: any) {
      setError('Failed to fetch product details. You can still add it manually.');
    } finally {
      setScraping(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const token = await user?.getIdToken();
      const response = await fetch('/api/wishes', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          wishlistId,
          title: formData.title,
          description: formData.description,
          url: formData.url,
          price: formData.price ? parseFloat(formData.price) : null,
          notes: formData.notes,
          priority: formData.priority,
          quantity: formData.quantity,
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to add item');
      }

      onSuccess();
    } catch (err: any) {
      setError(err.message || 'Failed to add item');
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b">
          <h2 className="text-2xl font-bold text-gray-900">Add Item to Wishlist</h2>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
              {error}
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Product URL (optional)
            </label>
            <div className="flex space-x-2">
              <input
                type="url"
                value={formData.url}
                onChange={(e) => setFormData({ ...formData, url: e.target.value })}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-purple-500 focus:border-purple-500"
                placeholder="https://example.com/product"
              />
              <button
                type="button"
                onClick={handleScrape}
                disabled={!formData.url || scraping}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {scraping ? 'Fetching...' : 'Auto-Fill'}
              </button>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Title *
            </label>
            <input
              type="text"
              required
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-purple-500 focus:border-purple-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Description
            </label>
            <textarea
              rows={3}
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-purple-500 focus:border-purple-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Price
              </label>
              <input
                type="number"
                step="0.01"
                value={formData.price}
                onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-purple-500 focus:border-purple-500"
                placeholder="0.00"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Quantity
              </label>
              <input
                type="number"
                min="1"
                value={formData.quantity}
                onChange={(e) => setFormData({ ...formData, quantity: parseInt(e.target.value) })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-purple-500 focus:border-purple-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Notes
            </label>
            <textarea
              rows={2}
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-purple-500 focus:border-purple-500"
              placeholder="Size, color, or other preferences..."
            />
          </div>

          <div className="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Adding...' : 'Add Item'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
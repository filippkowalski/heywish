'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Image from 'next/image';

interface Wish {
  id: string;
  title: string;
  url?: string;
  price?: number;
  image_url?: string;
  notes?: string;
  is_reserved: boolean;
  reserved_by_viewer?: boolean;
  created_at: string;
}

interface Wishlist {
  id: string;
  title: string;
  description?: string;
  owner_name: string;
  created_at: string;
  share_url: string;
  items_count: number;
  reserved_count: number;
}

export default function PublicWishlistPage() {
  const params = useParams();
  const token = params.token as string;
  
  const [wishlist, setWishlist] = useState<Wishlist | null>(null);
  const [wishes, setWishes] = useState<Wish[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showReserveModal, setShowReserveModal] = useState(false);
  const [selectedWish, setSelectedWish] = useState<Wish | null>(null);
  const [reserverName, setReserverName] = useState('');
  const [reserverEmail, setReserverEmail] = useState('');
  const [showShareToast, setShowShareToast] = useState(false);

  useEffect(() => {
    fetchWishlist();
  }, [token]);

  const fetchWishlist = async () => {
    try {
      // Include credentials to send cookies
      const response = await fetch(`/api/public/wishlists/${token}`, {
        credentials: 'include'
      });
      
      if (!response.ok) {
        if (response.status === 404) {
          setError('This wishlist does not exist or is private.');
        } else {
          setError('Failed to load wishlist. Please try again.');
        }
        return;
      }
      
      const data = await response.json();
      setWishlist(data.wishlist);
      setWishes(data.wishes);
    } catch (err) {
      setError('Failed to load wishlist. Please check your connection.');
    } finally {
      setLoading(false);
    }
  };

  const handleReserveClick = (wish: Wish) => {
    if (wish.is_reserved) {
      // Check if this user reserved it (from backend)
      if (wish.reserved_by_viewer) {
        handleUnreserve(wish.id);
      } else {
        alert('This item is already reserved by someone else.');
      }
    } else {
      setSelectedWish(wish);
      setShowReserveModal(true);
    }
  };

  const handleReserve = async () => {
    if (!selectedWish) return;
    
    try {
      const response = await fetch(`/api/public/wishlists/${token}`, {
        method: 'POST',
        credentials: 'include', // Include cookies
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          wishId: selectedWish.id,
          reserverName: reserverName || 'Anonymous',
          reserverEmail: reserverEmail || undefined,
        }),
      });
      
      if (response.ok) {
        // Just reload the wishlist to get fresh data from server
        await fetchWishlist();
        
        setShowReserveModal(false);
        setSelectedWish(null);
        setReserverName('');
        setReserverEmail('');
        
        alert('Item reserved successfully! The gift giver will be notified.');
      } else {
        const error = await response.json();
        alert(error.error || 'Failed to reserve item');
      }
    } catch (err) {
      alert('Failed to reserve item. Please try again.');
    }
  };

  const handleUnreserve = async (wishId: string) => {
    if (!confirm('Are you sure you want to unreserve this item?')) return;
    
    try {
      // The server will use the cookie to identify the reserver
      const response = await fetch(
        `/api/public/wishlists/${token}?wishId=${wishId}`,
        { 
          method: 'DELETE',
          credentials: 'include'
        }
      );
      
      if (response.ok) {
        // Just reload the wishlist to get fresh data from server
        await fetchWishlist();
        alert('Item unreserved successfully!');
      } else {
        alert('Failed to unreserve item');
      }
    } catch (err) {
      alert('Failed to unreserve item. Please try again.');
    }
  };

  const handleShare = () => {
    if (wishlist) {
      navigator.clipboard.writeText(wishlist.share_url);
      setShowShareToast(true);
      setTimeout(() => setShowShareToast(false), 3000);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-purple-600 border-t-transparent"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <div className="text-center">
          <div className="text-6xl mb-4">🎁</div>
          <h1 className="text-2xl font-bold text-gray-900 mb-2">Oops!</h1>
          <p className="text-gray-600">{error}</p>
        </div>
      </div>
    );
  }

  if (!wishlist || !wishes) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-purple-600 to-purple-700 text-white">
        <div className="max-w-4xl mx-auto px-4 py-8">
          <div className="flex justify-between items-start mb-4">
            <div>
              <h1 className="text-3xl font-bold mb-2">{wishlist.title}</h1>
              {wishlist.description && (
                <p className="text-purple-100">{wishlist.description}</p>
              )}
              <p className="text-sm text-purple-200 mt-2">
                By {wishlist.owner_name} • {wishlist.items_count} items • {wishlist.reserved_count} reserved
              </p>
            </div>
            <button
              onClick={handleShare}
              className="bg-white/20 hover:bg-white/30 px-4 py-2 rounded-lg transition-colors flex items-center gap-2"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m9.032 4.026a9.001 9.001 0 01-7.432 0m9.032-4.026A9.001 9.001 0 0112 3c-4.474 0-8.268 3.12-9.032 7.326m0 4.026A9.001 9.001 0 0112 21c4.474 0 8.268-3.12 9.032-7.326" />
              </svg>
              Share
            </button>
          </div>
        </div>
      </div>

      {/* Toast Notification */}
      {showShareToast && (
        <div className="fixed top-4 right-4 bg-green-600 text-white px-4 py-2 rounded-lg shadow-lg z-50 animate-slide-in">
          Link copied to clipboard!
        </div>
      )}

      {/* Instructions */}
      <div className="max-w-4xl mx-auto px-4 py-6">
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <p className="text-blue-800 text-sm">
            💡 <strong>How it works:</strong> Click on any item to reserve it for {wishlist.owner_name}. 
            Only you will know which item you reserved - it helps keep the gift a surprise!
          </p>
        </div>
      </div>

      {/* Wishes Grid */}
      <div className="max-w-4xl mx-auto px-4 pb-12">
        {wishes.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-500">No items in this wishlist yet.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {wishes.map((wish) => {
              // Check if this viewer reserved it (from backend)
              const isMyReservation = wish.reserved_by_viewer === true;
              
              return (
                <div
                  key={wish.id}
                  className={`bg-white rounded-lg shadow-md overflow-hidden transition-all hover:shadow-lg ${
                    wish.is_reserved && !isMyReservation ? 'opacity-60' : ''
                  }`}
                >
                  {wish.image_url && (
                    <div className="aspect-square relative bg-gray-100">
                      <img
                        src={wish.image_url}
                        alt={wish.title}
                        className="w-full h-full object-cover"
                      />
                      {wish.is_reserved && (
                        <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
                          <span className="bg-white px-3 py-1 rounded-full text-sm font-medium">
                            {isMyReservation ? 'Reserved by you' : 'Reserved'}
                          </span>
                        </div>
                      )}
                    </div>
                  )}
                  
                  <div className="p-4">
                    <h3 className="font-semibold text-gray-900 mb-1">{wish.title}</h3>
                    
                    {wish.price && (
                      <p className="text-lg font-bold text-purple-600 mb-2">
                        ${wish.price.toFixed(2)}
                      </p>
                    )}
                    
                    {wish.notes && (
                      <p className="text-sm text-gray-600 mb-3">{wish.notes}</p>
                    )}
                    
                    <div className="flex gap-2">
                      {wish.url && (
                        <a
                          href={wish.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex-1 bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-2 rounded text-sm text-center transition-colors"
                        >
                          View Item
                        </a>
                      )}
                      
                      <button
                        onClick={() => handleReserveClick(wish)}
                        className={`flex-1 px-3 py-2 rounded text-sm transition-colors ${
                          wish.is_reserved
                            ? isMyReservation
                              ? 'bg-red-600 hover:bg-red-700 text-white'
                              : 'bg-gray-300 text-gray-500 cursor-not-allowed'
                            : 'bg-purple-600 hover:bg-purple-700 text-white'
                        }`}
                        disabled={wish.is_reserved && !isMyReservation}
                      >
                        {wish.is_reserved
                          ? isMyReservation
                            ? 'Unreserve'
                            : 'Reserved'
                          : 'Reserve'}
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Reserve Modal */}
      {showReserveModal && selectedWish && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-md w-full p-6">
            <h2 className="text-xl font-bold mb-4">Reserve "{selectedWish.title}"</h2>
            
            <p className="text-gray-600 mb-4">
              Let {wishlist.owner_name} know who reserved this gift (optional):
            </p>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Your Name (optional)
                </label>
                <input
                  type="text"
                  value={reserverName}
                  onChange={(e) => setReserverName(e.target.value)}
                  placeholder="Anonymous"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-600"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Your Email (optional)
                </label>
                <input
                  type="email"
                  value={reserverEmail}
                  onChange={(e) => setReserverEmail(e.target.value)}
                  placeholder="For updates about this wishlist"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-600"
                />
              </div>
            </div>
            
            <div className="flex gap-3 mt-6">
              <button
                onClick={() => {
                  setShowReserveModal(false);
                  setSelectedWish(null);
                  setReserverName('');
                  setReserverEmail('');
                }}
                className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleReserve}
                className="flex-1 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700"
              >
                Reserve Item
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
'use client';

import Link from 'next/link';
import Navigation from '@/components/Navigation';
import { useAuth } from '@/contexts/AuthContext';

export default function Home() {
  const { user, dbUser } = useAuth();

  return (
    <>
      <Navigation />
      <div className="min-h-screen bg-gradient-to-b from-purple-50 to-white">
        {/* Hero Section */}
        <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-16">
          <div className="text-center">
            <h1 className="text-5xl font-bold text-gray-900 mb-6">
              Save, Share & Discover
              <span className="text-purple-600"> Perfect Gifts</span>
            </h1>
            <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
              Create wishlists from any website, share with friends and family, 
              and never receive duplicate gifts again.
            </p>
            <div className="flex justify-center space-x-4">
              {user && !user.isAnonymous ? (
                <Link
                  href="/wishlists"
                  className="bg-purple-600 text-white px-8 py-3 rounded-lg font-semibold hover:bg-purple-700 transition"
                >
                  My Wishlists
                </Link>
              ) : (
                <>
                  <Link
                    href="/wishlists/new"
                    className="bg-purple-600 text-white px-8 py-3 rounded-lg font-semibold hover:bg-purple-700 transition"
                  >
                    Create Your First Wishlist
                  </Link>
                  <Link
                    href="/auth/signup"
                    className="bg-white text-purple-600 px-8 py-3 rounded-lg font-semibold border-2 border-purple-600 hover:bg-purple-50 transition"
                  >
                    Sign Up Free
                  </Link>
                </>
              )}
            </div>
            {user?.isAnonymous && (
              <p className="text-sm text-gray-500 mt-4">
                No signup required - start creating wishlists instantly!
              </p>
            )}
          </div>
        </section>

        {/* Features Section */}
        <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
          <h2 className="text-3xl font-bold text-center text-gray-900 mb-12">
            Why Choose HeyWish?
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            <div className="text-center">
              <div className="bg-purple-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-8 h-8 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold mb-2">Save from Anywhere</h3>
              <p className="text-gray-600">
                Add items from any website with our browser extension or mobile app
              </p>
            </div>
            
            <div className="text-center">
              <div className="bg-purple-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-8 h-8 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m9.032 4.024A9.003 9.003 0 0112 21a9.003 9.003 0 01-5.716-2.318m11.432 0A9.003 9.003 0 0012 3a9.003 9.003 0 00-5.716 2.318m11.432 13.364L21 21m-3.284-2.318l3.284 3.284" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold mb-2">Smart Price Tracking</h3>
              <p className="text-gray-600">
                Get notified when prices drop on items you want
              </p>
            </div>
            
            <div className="text-center">
              <div className="bg-purple-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-8 h-8 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold mb-2">Social Sharing</h3>
              <p className="text-gray-600">
                Share wishlists with friends and secretly reserve gifts
              </p>
            </div>
          </div>
        </section>

        {/* How It Works */}
        <section className="bg-gray-50 py-16">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <h2 className="text-3xl font-bold text-center text-gray-900 mb-12">
              How It Works
            </h2>
            <div className="grid md:grid-cols-4 gap-8">
              <div className="text-center">
                <div className="text-4xl font-bold text-purple-600 mb-4">1</div>
                <h3 className="font-semibold mb-2">Browse & Save</h3>
                <p className="text-sm text-gray-600">
                  Find something you love online
                </p>
              </div>
              <div className="text-center">
                <div className="text-4xl font-bold text-purple-600 mb-4">2</div>
                <h3 className="font-semibold mb-2">Add to Wishlist</h3>
                <p className="text-sm text-gray-600">
                  Click our extension or share to app
                </p>
              </div>
              <div className="text-center">
                <div className="text-4xl font-bold text-purple-600 mb-4">3</div>
                <h3 className="font-semibold mb-2">Share with Friends</h3>
                <p className="text-sm text-gray-600">
                  Send your wishlist link to anyone
                </p>
              </div>
              <div className="text-center">
                <div className="text-4xl font-bold text-purple-600 mb-4">4</div>
                <h3 className="font-semibold mb-2">Get Perfect Gifts</h3>
                <p className="text-sm text-gray-600">
                  Friends can secretly reserve items
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* CTA Section */}
        <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
          <div className="bg-purple-600 rounded-2xl p-12 text-center text-white">
            <h2 className="text-3xl font-bold mb-4">
              Ready to Start Your Wishlist?
            </h2>
            <p className="text-xl mb-8 opacity-90">
              Join thousands of happy users who never miss the perfect gift
            </p>
            <Link
              href="/wishlists/new"
              className="bg-white text-purple-600 px-8 py-3 rounded-lg font-semibold hover:bg-gray-100 transition inline-block"
            >
              Create Your Wishlist Now
            </Link>
          </div>
        </section>
      </div>
    </>
  );
}
'use client';

export const runtime = 'edge';

import { useState, useEffect, useMemo } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { ChevronRight } from 'lucide-react';
import { useAuth } from '@/lib/auth/AuthContext.client';
import { useApiAuth } from '@/lib/hooks/useApiAuth';
import { SignInModal } from '@/components/auth/SignInModal.client';
import { WishSlideOver } from '@/components/wish/WishSlideOver.client';
import { GuideItemGrid } from '@/components/gift-guides/guide-item-grid';
import { allGuides, guideItems } from '@/lib/gift-guides/guide-data';
import type { GuideItem } from '@/lib/gift-guides/types';
import type { Wishlist } from '@/lib/api';

export default function GuideDetailPage() {
  const params = useParams();
  const guideSlug = params?.guideSlug as string;
  const { user, backendUser } = useAuth();
  const { getMyWishlists } = useApiAuth();
  const isLoggedIn = !!user && !!backendUser;

  // State management
  const [showSignIn, setShowSignIn] = useState(false);
  const [showWishModal, setShowWishModal] = useState(false);
  const [selectedItem, setSelectedItem] = useState<GuideItem | null>(null);
  const [wishlists, setWishlists] = useState<Wishlist[]>([]);

  // Find the current guide
  const guide = useMemo(() => {
    return allGuides.find((g) => g.slug === guideSlug);
  }, [guideSlug]);

  // Get guide items
  const items = useMemo(() => {
    return guideItems[guideSlug] || [];
  }, [guideSlug]);

  // Fetch user's wishlists when logged in
  useEffect(() => {
    if (isLoggedIn) {
      const fetchWishlists = async () => {
        try {
          const data = await getMyWishlists();
          setWishlists(data);
        } catch (error) {
          console.error('Failed to fetch wishlists:', error);
        }
      };

      fetchWishlists();
    }
  }, [isLoggedIn, getMyWishlists]);

  // Handle save button click
  const handleSaveItem = (item: GuideItem) => {
    setSelectedItem(item);

    if (!isLoggedIn) {
      setShowSignIn(true);
      return;
    }

    setShowWishModal(true);
  };

  // After user signs in, open the wish modal
  useEffect(() => {
    if (isLoggedIn && selectedItem && !showWishModal) {
      setShowWishModal(true);
    }
  }, [isLoggedIn, selectedItem, showWishModal]);

  // Prepare prefilled data for WishSlideOver
  const prefilledData = selectedItem
    ? {
        title: selectedItem.title,
        description: selectedItem.description,
        url: selectedItem.url,
        price: selectedItem.price,
        currency: selectedItem.currency,
        images: [selectedItem.image],
      }
    : undefined;

  // 404 if guide not found
  if (!guide) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <div className="text-center">
          <h1 className="mb-2 font-poppins text-2xl font-bold text-gray-900">
            Guide Not Found
          </h1>
          <p className="mb-6 text-gray-600">
            The gift guide you&apos;re looking for doesn&apos;t exist.
          </p>
          <Link
            href="/gift-guides"
            className="text-sm font-medium text-primary hover:underline"
          >
            ← Back to Gift Guides
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Breadcrumb */}
      <div className="border-b bg-white">
        <div className="container mx-auto px-4 py-3">
          <nav className="flex items-center gap-2 text-sm text-gray-600">
            <Link href="/gift-guides" className="hover:text-gray-900">
              Gift Guides
            </Link>
            <ChevronRight className="h-4 w-4" />
            <span className="text-gray-900">{guide.categoryTag}</span>
          </nav>
        </div>
      </div>

      {/* Header Section */}
      <div className="border-b bg-white">
        <div className="container mx-auto px-4 py-8 md:py-12">
          <div className="mx-auto max-w-4xl">
            {/* Category Tag */}
            <div className="mb-3">
              <span className="text-xs font-semibold uppercase tracking-wider text-rose-600">
                {guide.categoryTag}
              </span>
            </div>

            {/* Title */}
            <h1 className="mb-4 font-poppins text-3xl font-bold leading-tight text-gray-900 md:text-4xl lg:text-5xl">
              {guide.title}
            </h1>

            {/* Description */}
            <p className="text-lg leading-relaxed text-gray-600">
              {guide.description}
            </p>
          </div>
        </div>
      </div>

      {/* Hero Image */}
      <div className="border-b bg-white">
        <div className="container mx-auto px-4">
          <div className="relative mx-auto aspect-[21/9] max-w-6xl overflow-hidden rounded-2xl bg-gray-100">
            <Image
              src={guide.heroImagePath}
              alt={guide.heroImageAlt}
              fill
              sizes="(max-width: 1280px) 100vw, 1280px"
              className="object-cover"
              priority
            />
          </div>
        </div>
      </div>

      {/* Guide Items */}
      <div className="container mx-auto px-4 py-8 md:py-12">
        {items.length > 0 ? (
          <>
            <div className="mb-6">
              <h2 className="font-poppins text-xl font-bold text-gray-900 md:text-2xl">
                {items.length} Gift {items.length === 1 ? 'Idea' : 'Ideas'}
              </h2>
            </div>
            <GuideItemGrid items={items} onSaveItem={handleSaveItem} />
          </>
        ) : (
            <div className="rounded-xl bg-white p-12 text-center shadow-sm">
              <p className="text-gray-600">
                Gift ideas for this guide are coming soon! Check back later for curated recommendations.
              </p>
              <Link
                href="/gift-guides"
                className="mt-4 inline-block text-sm font-medium text-primary hover:underline"
              >
                ← Browse Other Guides
              </Link>
            </div>
          )}
      </div>

      {/* Sign In Modal */}
      <SignInModal open={showSignIn} onOpenChange={setShowSignIn} />

      {/* Wish Slide Over */}
      {isLoggedIn && (
        <WishSlideOver
          open={showWishModal}
          onClose={() => {
            setShowWishModal(false);
            setSelectedItem(null);
          }}
          onSuccess={() => {
            setShowWishModal(false);
            setSelectedItem(null);
          }}
          wishlists={wishlists}
          prefilledData={prefilledData}
        />
      )}
    </div>
  );
}

'use client';

export const runtime = 'edge';

import { useMemo } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { ChevronRight } from 'lucide-react';
import { HeroGuideCard } from '@/components/gift-guides/hero-guide-card';
import { allGuides, categories } from '@/lib/gift-guides/guide-data';

export default function CategoryDetailPage() {
  const params = useParams();
  const categorySlug = params?.categorySlug as string;

  // Find the current category
  const category = useMemo(() => {
    return categories.find((c) => c.slug === categorySlug);
  }, [categorySlug]);

  // Filter guides by category
  const categoryGuides = useMemo(() => {
    return allGuides.filter((guide) =>
      guide.categories?.includes(categorySlug)
    );
  }, [categorySlug]);

  // 404 if category not found
  if (!category) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <div className="text-center">
          <h1 className="mb-2 font-poppins text-2xl font-bold text-gray-900">
            Category Not Found
          </h1>
          <p className="mb-6 text-gray-600">
            The category you&apos;re looking for doesn&apos;t exist.
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
            <span className="text-gray-900">{category.label}</span>
          </nav>
        </div>
      </div>

      {/* Header Section */}
      <div className="border-b bg-gradient-to-b from-rose-50/50 to-gray-50">
        <div className="container mx-auto px-4 py-12 md:py-16">
          <div className="mx-auto max-w-3xl text-center">
            {/* Category Icon */}
            <div className="mb-4 flex justify-center">
              <div className="flex h-16 w-16 items-center justify-center rounded-full bg-white text-4xl shadow-sm">
                {category.icon}
              </div>
            </div>

            {/* Category Name */}
            <h1 className="mb-4 font-poppins text-4xl font-bold tracking-tight text-gray-900 md:text-5xl">
              {category.label}
            </h1>

            {/* Category Description */}
            {category.description && (
              <p className="text-lg text-gray-600">{category.description}</p>
            )}
          </div>
        </div>
      </div>

      {/* Category Guides */}
      <div className="container mx-auto px-4 py-8 md:py-12">
        <div className="mx-auto max-w-6xl">
          {categoryGuides.length > 0 ? (
            <>
              <div className="mb-6">
                <h2 className="font-poppins text-xl font-bold text-gray-900 md:text-2xl">
                  {categoryGuides.length} {categoryGuides.length === 1 ? 'Guide' : 'Guides'}
                </h2>
              </div>
              <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                {categoryGuides.map((guide) => (
                  <div key={guide.slug} className="h-full">
                    <HeroGuideCard guide={guide} />
                  </div>
                ))}
              </div>
            </>
          ) : (
            <div className="rounded-xl bg-white p-12 text-center shadow-sm">
              <div className="mx-auto mb-4 flex h-20 w-20 items-center justify-center rounded-full bg-gray-100 text-5xl">
                {category.icon}
              </div>
              <h3 className="mb-2 font-poppins text-xl font-bold text-gray-900">
                No Guides Yet
              </h3>
              <p className="mb-6 text-gray-600">
                We&apos;re working on curating amazing {category.label.toLowerCase()} gift guides. Check back soon!
              </p>
              <Link
                href="/gift-guides"
                className="inline-block text-sm font-medium text-primary hover:underline"
              >
                ← Browse All Guides
              </Link>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

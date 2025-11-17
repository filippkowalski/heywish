'use client';

import { useState, useMemo } from 'react';
import { Gift } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { HeroGuideCard } from '@/components/gift-guides/hero-guide-card';
import { SidebarGuideCard } from '@/components/gift-guides/sidebar-guide-card';
import { CategoryCard } from '@/components/gift-guides/category-card';
import { heroGuide, sidebarGuides, categories, allGuides } from '@/lib/gift-guides/guide-data';

export default function GiftGuidesPage() {
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  // Filter guides by category
  const filteredGuides = useMemo(() => {
    if (selectedCategory === 'all') {
      return allGuides;
    }
    return allGuides.filter((guide) =>
      guide.categories?.includes(selectedCategory)
    );
  }, [selectedCategory]);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Hero Section */}
      <div className="border-b bg-gradient-to-b from-rose-50/50 to-gray-50">
        <div className="container mx-auto px-4 py-12 md:py-16">
          <div className="mx-auto max-w-3xl text-center">
            <div className="mb-4 inline-flex items-center gap-2 rounded-full bg-rose-100 px-4 py-1.5 text-sm font-medium text-rose-700">
              <Gift className="h-4 w-4" />
              Gift Guides
            </div>
            <h1 className="mb-4 font-poppins text-4xl font-bold tracking-tight text-gray-900 md:text-5xl">
              Curated Gift Guides for Every Occasion
            </h1>
            <p className="text-lg text-gray-600">
              Discover thoughtfully curated gift collections for holidays, celebrations, and special moments.
              Save any item to your wishlist with a single click.
            </p>
          </div>
        </div>
      </div>

      {/* Category Filter */}
      <div className="sticky top-0 z-10 border-b bg-white/95 shadow-sm backdrop-blur supports-[backdrop-filter]:bg-white/80">
        <div className="container mx-auto px-4 py-4">
          <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
            <Button
              variant={selectedCategory === 'all' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setSelectedCategory('all')}
              className="whitespace-nowrap"
            >
              All Guides
            </Button>
            {categories.map((category) => (
              <Button
                key={category.slug}
                variant={selectedCategory === category.slug ? 'default' : 'outline'}
                size="sm"
                onClick={() => setSelectedCategory(category.slug)}
                className="whitespace-nowrap"
              >
                <span className="mr-1.5">{category.icon}</span>
                {category.label}
              </Button>
            ))}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="container mx-auto px-4 py-8 md:px-6 lg:px-20">
        {selectedCategory === 'all' ? (
          <>
            {/* Featured Guides Section */}
            <div className="mb-12 grid gap-6 lg:grid-cols-[1.2fr,0.8fr]">
              {/* Hero Guide */}
              <div>
                <HeroGuideCard guide={heroGuide} />
              </div>

              {/* Sidebar Guides */}
              <div className="space-y-4">
                {sidebarGuides.map((guide) => (
                  <SidebarGuideCard key={guide.slug} guide={guide} />
                ))}
              </div>
            </div>

            {/* Guides by Category Section */}
            <section className="mt-12">
              <h2 className="mb-6 font-poppins text-2xl font-bold text-gray-900 md:text-3xl">
                Guides by Category
              </h2>
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                {categories.map((category) => (
                  <CategoryCard key={category.slug} category={category} />
                ))}
              </div>
            </section>
          </>
        ) : (
          /* Filtered View */
          <div>
            <div className="mb-6">
              <h2 className="font-poppins text-2xl font-bold text-gray-900 md:text-3xl">
                {categories.find((c) => c.slug === selectedCategory)?.label} Guides
              </h2>
              <p className="mt-2 text-gray-600">
                Showing {filteredGuides.length} {filteredGuides.length === 1 ? 'guide' : 'guides'}
              </p>
            </div>

            {filteredGuides.length > 0 ? (
              <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                {filteredGuides.map((guide) => (
                  <div key={guide.slug} className="h-full">
                    <HeroGuideCard guide={guide} />
                  </div>
                ))}
              </div>
            ) : (
              <div className="flex min-h-[300px] items-center justify-center rounded-lg border-2 border-dashed border-gray-200 bg-white">
                <div className="text-center">
                  <Gift className="mx-auto mb-3 h-12 w-12 text-gray-300" />
                  <p className="text-sm text-gray-500">
                    No guides available in this category yet. Check back soon!
                  </p>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

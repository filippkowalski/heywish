'use client';

import Link from 'next/link';
import { ChevronRight } from 'lucide-react';
import { GuideCategory } from '@/lib/gift-guides/types';

interface CategoryCardProps {
  category: GuideCategory;
}

export function CategoryCard({ category }: CategoryCardProps) {
  return (
    <Link href={`/gift-guides/category/${category.slug}`} className="group block">
      <div className="flex h-20 items-center justify-between gap-3 overflow-hidden rounded-2xl border border-gray-100 bg-white px-6 shadow-sm transition-all duration-300 hover:border-gray-200 hover:bg-gray-50 hover:shadow-md md:h-24">
        {/* Icon */}
        <div className="text-2xl md:text-3xl">{category.icon}</div>

        {/* Label */}
        <div className="flex-1">
          <span className="font-poppins text-sm font-semibold text-gray-900 md:text-base">
            {category.label}
          </span>
        </div>

        {/* Chevron */}
        <ChevronRight
          className="h-5 w-5 flex-shrink-0 text-gray-400 transition-transform duration-300 group-hover:translate-x-1 group-hover:text-gray-600"
          strokeWidth={2.5}
        />
      </div>
    </Link>
  );
}

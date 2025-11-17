'use client';

import Image from 'next/image';
import Link from 'next/link';
import { GiftGuide } from '@/lib/gift-guides/types';

interface SidebarGuideCardProps {
  guide: GiftGuide;
}

export function SidebarGuideCard({ guide }: SidebarGuideCardProps) {
  return (
    <Link href={`/gift-guides/${guide.slug}`} className="group block">
      <div className="overflow-hidden rounded-2xl bg-white p-4 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-lg md:p-5">
        <div className="flex gap-4">
          {/* Thumbnail Image */}
          <div className="relative h-24 w-24 flex-shrink-0 overflow-hidden rounded-xl bg-gray-100 md:h-28 md:w-28">
            <Image
              src={guide.heroImagePath}
              alt={guide.heroImageAlt}
              fill
              sizes="112px"
              className="object-cover transition-transform duration-300 group-hover:scale-110"
            />
          </div>

          {/* Text Content */}
          <div className="flex min-w-0 flex-1 flex-col justify-center space-y-1.5">
            {/* Category Tag */}
            <span className="text-[10px] font-semibold uppercase tracking-wider text-rose-600 md:text-xs">
              {guide.categoryTag}
            </span>

            {/* Title */}
            <h3 className="line-clamp-2 font-poppins text-sm font-bold leading-snug text-gray-900 md:text-base">
              {guide.title}
            </h3>

            {/* Description */}
            <p className="line-clamp-2 text-xs leading-relaxed text-gray-600 md:text-sm">
              {guide.description}
            </p>
          </div>
        </div>
      </div>
    </Link>
  );
}

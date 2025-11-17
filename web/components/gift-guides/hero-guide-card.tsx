'use client';

import Image from 'next/image';
import Link from 'next/link';
import { GiftGuide } from '@/lib/gift-guides/types';

interface HeroGuideCardProps {
  guide: GiftGuide;
}

export function HeroGuideCard({ guide }: HeroGuideCardProps) {
  return (
    <Link href={`/gift-guides/${guide.slug}`} className="group block">
      <div className="overflow-hidden rounded-3xl bg-white shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-xl">
        {/* Image Container */}
        <div className="relative aspect-video w-full overflow-hidden bg-gray-100">
          <Image
            src={guide.heroImagePath}
            alt={guide.heroImageAlt}
            fill
            sizes="(max-width: 768px) 100vw, 60vw"
            className="object-cover transition-transform duration-300 group-hover:scale-105"
            priority
          />
        </div>

        {/* Text Content */}
        <div className="space-y-3 p-6">
          {/* Category Tag */}
          <div className="inline-block">
            <span className="text-xs font-semibold uppercase tracking-wider text-rose-600">
              {guide.categoryTag}
            </span>
          </div>

          {/* Title */}
          <h2 className="font-poppins text-2xl font-bold leading-tight text-gray-900 md:text-3xl">
            {guide.title}
          </h2>

          {/* Description */}
          <p className="text-base leading-relaxed text-gray-600">
            {guide.description}
          </p>
        </div>
      </div>
    </Link>
  );
}

'use client';

import { GuideItem } from '@/lib/gift-guides/types';
import { GuideItemCard } from './guide-item-card';

interface GuideItemGridProps {
  items: GuideItem[];
  onSaveItem: (item: GuideItem) => void;
}

export function GuideItemGrid({ items, onSaveItem }: GuideItemGridProps) {
  if (items.length === 0) {
    return (
      <div className="flex min-h-[300px] items-center justify-center rounded-lg border-2 border-dashed border-gray-200 bg-gray-50">
        <p className="text-sm text-muted-foreground">
          No items available in this guide yet. Check back soon!
        </p>
      </div>
    );
  }

  return (
    <div className="columns-2 gap-3 sm:columns-2 md:columns-3 lg:columns-4 xl:columns-5">
      {items.map((item) => (
        <GuideItemCard key={item.id} item={item} onSave={onSaveItem} />
      ))}
    </div>
  );
}

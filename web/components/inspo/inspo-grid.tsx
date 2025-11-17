'use client';

import { InspoItem } from '@/lib/inspo/inspo-items';
import { InspoCard } from './inspo-card';

interface InspoGridProps {
  items: InspoItem[];
  onSaveItem: (item: InspoItem) => void;
}

export function InspoGrid({ items, onSaveItem }: InspoGridProps) {
  if (items.length === 0) {
    return (
      <div className="flex min-h-[400px] items-center justify-center">
        <p className="text-muted-foreground">No items found</p>
      </div>
    );
  }

  return (
    <div className="columns-2 gap-3 sm:columns-2 md:columns-3 lg:columns-4 xl:columns-5">
      {items.map((item) => (
        <InspoCard key={item.id} item={item} onSave={onSaveItem} />
      ))}
    </div>
  );
}

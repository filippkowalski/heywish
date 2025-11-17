'use client';

import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Heart } from 'lucide-react';
import Image from 'next/image';
import { InspoItem } from '@/lib/inspo/inspo-items';

interface InspoCardProps {
  item: InspoItem;
  onSave: (item: InspoItem) => void;
}

export function InspoCard({ item, onSave }: InspoCardProps) {
  return (
    <Card className="group/card mb-3 flex flex-col gap-0 overflow-hidden border border-black/10 transition-shadow hover:shadow-md">
      {/* Image */}
      <div className="relative aspect-square w-full overflow-hidden bg-muted">
        <Image
          src={item.image}
          alt={item.title}
          fill
          sizes="(max-width: 640px) 50vw, (max-width: 768px) 33vw, (max-width: 1024px) 25vw, 20vw"
          className="object-cover transition-transform duration-300 group-hover/card:scale-105"
        />
      </div>

      {/* Content */}
      <CardContent className="flex flex-1 flex-col gap-2 px-3 py-3">
        {/* Title */}
        <h3 className="text-sm font-semibold leading-tight line-clamp-2">
          {item.title}
        </h3>

        {/* Description */}
        {item.description && (
          <p className="text-xs text-muted-foreground line-clamp-2">
            {item.description}
          </p>
        )}

        {/* Price and Save Button */}
        <div className="mt-auto flex items-center justify-between gap-2">
          <span className="text-sm font-semibold">
            {item.currency === 'USD' && '$'}
            {item.price.toFixed(2)}
          </span>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => onSave(item)}
            className="h-8 gap-1.5 text-xs hover:bg-primary/10 hover:text-primary"
          >
            <Heart className="h-3.5 w-3.5" />
            Save
          </Button>
        </div>

        {/* Category Tag */}
        {item.category && (
          <div className="mt-1">
            <span className="inline-block rounded-full bg-muted px-2 py-0.5 text-[10px] font-medium text-muted-foreground">
              {item.category}
            </span>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

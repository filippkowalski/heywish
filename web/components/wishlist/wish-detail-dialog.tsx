'use client';

import { useEffect, useState, type ReactNode } from "react";
import Image from "next/image";
import { Gift } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
} from "@/components/ui/dialog";
import type { Wish } from "@/lib/api";

function formatPrice(amount?: number, currency: string = "USD") {
  if (amount == null) return null;

  try {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency,
      maximumFractionDigits: 0,
    }).format(amount);
  } catch {
    return `$${amount}`;
  }
}

type FooterRendererContext = {
  close: () => void;
  isReserved: boolean;
  isMine: boolean;
};

type FooterRenderer =
  | ReactNode
  | ((context: FooterRendererContext) => ReactNode);

export interface WishDetailDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  wish: Wish | null;
  onReserve?: () => void;
  onCancel?: () => void;
  isMine?: boolean;
  footer?: FooterRenderer;
}

export function WishDetailDialog({
  open,
  onOpenChange,
  wish,
  onReserve,
  onCancel,
  isMine = false,
  footer,
}: WishDetailDialogProps) {
  const [currentImageIndex, setCurrentImageIndex] = useState(0);

  useEffect(() => {
    setCurrentImageIndex(0);
  }, [wish?.id]);

  if (!wish) return null;

  const images = wish.images ?? [];
  const price = formatPrice(wish.price, wish.currency);
  const isReserved = wish.status === "reserved";

  const handleClose = () => onOpenChange(false);

  const renderFooter = () => {
    if (footer) {
      return typeof footer === "function"
        ? footer({ close: handleClose, isReserved, isMine })
        : footer;
    }

    if (isReserved) {
      return (
        <div className="flex flex-col sm:flex-row gap-2 sm:gap-3">
          {isMine && onCancel && (
            <Button
              variant="outline"
              onClick={onCancel}
              className="flex-1 h-11 sm:h-12 text-base font-medium"
            >
              Cancel reservation
            </Button>
          )}
          <Button
            variant="secondary"
            onClick={handleClose}
            className="flex-1 h-11 sm:h-12 text-base font-medium"
          >
            Close
          </Button>
        </div>
      );
    }

    return (
      <div className="flex flex-col-reverse sm:flex-row gap-2 sm:gap-3">
        <Button
          variant="outline"
          onClick={handleClose}
          className="flex-1 h-11 sm:h-12 text-base font-medium"
        >
          Close
        </Button>
        {onReserve && (
          <Button
            onClick={onReserve}
            className="flex-1 h-11 sm:h-12 text-base font-medium"
          >
            Reserve this item
          </Button>
        )}
      </div>
    );
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl max-h-[95vh] p-0 gap-0 overflow-hidden flex flex-col">
        {/* Image Gallery Section */}
        {images.length > 0 ? (
          <div className="relative w-full bg-muted" style={{ aspectRatio: "1/1" }}>
            <Image
              src={images[currentImageIndex]}
              alt={wish.title}
              fill
              className="object-cover"
              sizes="(min-width: 768px) 50vw, 100vw"
              priority
            />
            {isReserved && (
              <div className="absolute top-4 right-4">
                <Badge variant="secondary" className="bg-black/80 text-white border-0 backdrop-blur-sm px-3 py-1.5 text-xs sm:text-sm">
                  {isMine ? "Reserved by you" : "Reserved"}
                </Badge>
              </div>
            )}

            {images.length > 1 && (
              <div className="absolute bottom-4 left-4">
                <Badge variant="secondary" className="bg-black/80 text-white border-0 backdrop-blur-sm px-2 py-1 text-xs">
                  {currentImageIndex + 1} / {images.length}
                </Badge>
              </div>
            )}
          </div>
        ) : (
          <div className="relative w-full bg-muted/30 flex items-center justify-center" style={{ aspectRatio: "1/1" }}>
            <Gift className="h-20 w-20 text-muted-foreground/30" />
            {isReserved && (
              <div className="absolute top-4 right-4">
                <Badge variant="secondary" className="bg-black/80 text-white border-0 backdrop-blur-sm px-3 py-1.5 text-xs sm:text-sm">
                  {isMine ? "Reserved by you" : "Reserved"}
                </Badge>
              </div>
            )}
          </div>
        )}

        {images.length > 1 && (
          <div className="flex gap-2 overflow-x-auto px-4 py-3 border-b bg-background scrollbar-thin">
            {images.map((img, idx) => (
              <button
                key={idx}
                onClick={() => setCurrentImageIndex(idx)}
                className={`relative flex-shrink-0 w-16 h-16 sm:w-20 sm:h-20 rounded-lg overflow-hidden border-2 transition-all ${
                  idx === currentImageIndex
                    ? "border-primary ring-2 ring-primary/20"
                    : "border-border/40 hover:border-border"
                }`}
              >
                <Image
                  src={img}
                  alt={`${wish.title} - Image ${idx + 1}`}
                  fill
                  className="object-cover"
                  sizes="80px"
                />
              </button>
            ))}
          </div>
        )}

        <div className="flex-1 overflow-y-auto">
          <div className="p-4 sm:p-6 space-y-4">
            <div className="space-y-2">
              <h2 className="text-xl sm:text-2xl font-semibold leading-tight">{wish.title}</h2>
              {price && (
                <div className="text-2xl sm:text-3xl font-bold text-primary">{price}</div>
              )}
            </div>

            {wish.description && (
              <div className="space-y-1.5">
                <h3 className="font-semibold text-sm text-muted-foreground uppercase tracking-wide">
                  Description
                </h3>
                <p className="text-foreground leading-relaxed text-sm sm:text-base">
                  {wish.description}
                </p>
              </div>
            )}

            {wish.url && (
              <a
                href={wish.url}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 text-primary hover:underline font-medium text-sm sm:text-base"
              >
                View product details →
              </a>
            )}

            {isReserved && (wish.reserverName || wish.reservedMessage) && (
              <div className="space-y-2 pt-4 border-t">
                <h3 className="font-semibold text-sm text-muted-foreground uppercase tracking-wide">
                  Reservation Details
                </h3>
                {wish.reserverName && (
                  <p className="text-sm">
                    Reserved by <span className="font-medium">{wish.reserverName}</span>
                  </p>
                )}
                {wish.reservedMessage && (
                  <p className="text-sm italic text-muted-foreground">
                    &quot;{wish.reservedMessage}&quot;
                  </p>
                )}
              </div>
            )}
          </div>
        </div>

        <div className="border-t bg-background p-4 sm:p-6">
          {renderFooter()}
        </div>
      </DialogContent>
    </Dialog>
  );
}

/**
 * Gift Guides Types
 * Type definitions for the gift guides feature
 */

export interface GuideItem {
  id: string;
  title: string;
  description: string;
  image: string;
  price: number;
  currency: string;
  url: string;
  category?: string;
  tags?: string[];
}

export interface GiftGuide {
  slug: string;
  categoryTag: string;
  title: string;
  description: string;
  heroImageAlt: string;
  heroImagePath: string;
  items?: GuideItem[];
  categories?: string[];
}

export interface GuideCategory {
  slug: string;
  label: string;
  icon: string;
  description?: string;
}

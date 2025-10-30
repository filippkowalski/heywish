import { z } from 'zod';

export const wishlistSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100, 'Name must be less than 100 characters'),
  description: z.string().max(500, 'Description must be less than 500 characters').optional(),
  visibility: z.enum(['public', 'friends', 'private']),
  coverImageUrl: z.string().url('Invalid image URL').optional().or(z.literal('')),
});

export const wishSchema = z.object({
  wishlistId: z.string().uuid('Invalid wishlist').optional(),
  title: z.string().min(1, 'Title is required').max(200, 'Title must be less than 200 characters'),
  description: z.string().max(1000, 'Description must be less than 1000 characters').optional(),
  url: z.string().url('Invalid URL').optional().or(z.literal('')),
  price: z.number().positive('Price must be positive').optional().or(z.literal(0)),
  currency: z.string().length(3, 'Currency must be 3 characters'),
  images: z.array(z.string().url('Invalid image URL')).optional(),
});

export type WishlistFormData = z.infer<typeof wishlistSchema>;
export type WishFormData = z.infer<typeof wishSchema>;

import { z } from 'zod';

// Our own shapes, not Fake Store's, so the data source can change without clients noticing.

export const categorySchema = z.object({
  /** URL-safe identifier, e.g. "mens-clothing". */
  slug: z.string().min(1),
  name: z.string().min(1),
});
export type Category = z.infer<typeof categorySchema>;

export const productSchema = z.object({
  /** String so that future sources (UUIDs, SKUs) fit without a contract change. */
  id: z.string().min(1),
  title: z.string(),
  description: z.string(),
  price: z.object({
    amount: z.number().nonnegative(),
    currency: z.string().length(3),
  }),
  imageUrl: z.string().url(),
  category: categorySchema,
  rating: z.object({
    average: z.number().min(0).max(5),
    count: z.number().int().nonnegative(),
  }),
});
export type Product = z.infer<typeof productSchema>;

export const productListResponseSchema = z.object({
  items: z.array(productSchema),
});
export type ProductListResponse = z.infer<typeof productListResponseSchema>;

export const categoryListResponseSchema = z.object({
  items: z.array(categorySchema),
});
export type CategoryListResponse = z.infer<typeof categoryListResponseSchema>;

export const categoryPageResponseSchema = z.object({
  category: categorySchema,
  topRated: z.array(productSchema),
  others: z.array(productSchema),
});
export type CategoryPageResponse = z.infer<typeof categoryPageResponseSchema>;

export const SEARCH_TERM_MAX_LENGTH = 100;

export const searchQuerySchema = z.object({
  search: z.string().trim().min(1).max(SEARCH_TERM_MAX_LENGTH).optional(),
});

import type { Category, Product } from '../domain/types.js';

/**
 * Kept small on purpose: filtering and ranking live in the services, so every adapter gets them.
 * Implementations throw UpstreamError when the source is unavailable.
 */
export interface ProductSource {
  listProducts(): Promise<Product[]>;
  /** Returns null when the product does not exist. */
  getProduct(id: string): Promise<Product | null>;
  listCategories(): Promise<Category[]>;
}

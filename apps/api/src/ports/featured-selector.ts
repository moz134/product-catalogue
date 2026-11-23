import type { Product } from '../domain/types.js';

export interface FeaturedSelector {
  select(candidates: readonly Product[], limit: number): Product[];
}

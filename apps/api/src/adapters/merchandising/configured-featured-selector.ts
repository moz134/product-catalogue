import type { Product } from '../../domain/types.js';
import type { FeaturedSelector } from '../../ports/featured-selector.js';

/**
 * The owner's chosen products (FEATURED_PRODUCT_IDS, in that order), topped up with the
 * best-rated candidates when fewer than `limit` of them are available.
 */
export class ConfiguredFeaturedSelector implements FeaturedSelector {
  constructor(private readonly curatedIds: readonly string[]) {}

  select(candidates: readonly Product[], limit: number): Product[] {
    const byId = new Map(candidates.map((p) => [p.id, p]));
    const chosen: Product[] = [];
    for (const id of this.curatedIds) {
      const product = byId.get(id);
      if (product && !chosen.includes(product)) chosen.push(product);
      if (chosen.length === limit) return chosen;
    }

    const topUp = candidates
      .filter((p) => !chosen.includes(p))
      .sort(byRatingDescending)
      .slice(0, limit - chosen.length);
    return [...chosen, ...topUp];
  }
}

export function byRatingDescending(a: Product, b: Product): number {
  return (
    b.rating.average - a.rating.average ||
    b.rating.count - a.rating.count ||
    a.id.localeCompare(b.id, undefined, { numeric: true })
  );
}

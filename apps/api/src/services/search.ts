import type { Product } from '../domain/types.js';

function normalise(value: string): string {
  return value
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '') // strip accents
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Case- and accent-insensitive substring search over title, description and category name.
 * Title matches come first. Runs in memory because Fake Store has no search endpoint.
 */
export function searchProducts(products: readonly Product[], term: string): Product[] {
  const needle = normalise(term);
  if (needle === '') return [];

  const titleMatches: Product[] = [];
  const otherMatches: Product[] = [];
  for (const product of products) {
    if (normalise(product.title).includes(needle)) {
      titleMatches.push(product);
    } else if (
      normalise(product.description).includes(needle) ||
      normalise(product.category.name).includes(needle)
    ) {
      otherMatches.push(product);
    }
  }
  return [...titleMatches, ...otherMatches];
}

import { describe, expect, it } from 'vitest';
import { searchProducts } from '../src/services/search.js';
import { makeProduct, sampleCatalogue } from './fixtures.js';

const ids = (products: { id: string }[]) => products.map((p) => p.id);

describe('searchProducts', () => {
  it('only returns products whose text matches the term', () => {
    expect(ids(searchProducts(sampleCatalogue(), 'ssd'))).toEqual(['2']);
  });

  it('is case-insensitive and ignores surrounding whitespace', () => {
    expect(ids(searchProducts(sampleCatalogue(), '  GOLD  '))).toEqual(['5']);
  });

  it('matches description and category name, listing title matches first', () => {
    // "backpack" is in product 1's title and product 6's description
    expect(ids(searchProducts(sampleCatalogue(), 'backpack'))).toEqual(['1', '6']);
    expect(ids(searchProducts(sampleCatalogue(), 'jewel'))).toEqual(['5', '6', '7']);
  });

  it('ignores accents', () => {
    const products = [makeProduct({ id: 'c', title: 'Café table' })];
    expect(ids(searchProducts(products, 'cafe'))).toEqual(['c']);
  });

  it('returns nothing for no match or a blank term', () => {
    expect(searchProducts(sampleCatalogue(), 'unicorn')).toEqual([]);
    expect(searchProducts(sampleCatalogue(), '   ')).toEqual([]);
  });
});

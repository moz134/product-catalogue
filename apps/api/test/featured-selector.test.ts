import { describe, expect, it } from 'vitest';
import { ConfiguredFeaturedSelector } from '../src/adapters/merchandising/configured-featured-selector.js';
import { sampleCatalogue } from './fixtures.js';

const ids = (products: { id: string }[]) => products.map((p) => p.id);

describe('ConfiguredFeaturedSelector', () => {
  it('returns the owner-chosen products, in the chosen order', () => {
    const selector = new ConfiguredFeaturedSelector(['6', '3', '1', '7', '4']);

    expect(ids(selector.select(sampleCatalogue(), 5))).toEqual(['6', '3', '1', '7', '4']);
  });

  it('tops up with the highest-rated products when fewer are chosen', () => {
    const selector = new ConfiguredFeaturedSelector(['3']);

    expect(ids(selector.select(sampleCatalogue(), 3))).toEqual(['3', '5', '2']);
  });

  it('falls back to rating alone when nothing is configured', () => {
    const selector = new ConfiguredFeaturedSelector([]);

    expect(ids(selector.select(sampleCatalogue(), 2))).toEqual(['5', '2']);
  });

  it('ignores chosen ids that are not in the candidate list, and duplicates', () => {
    const selector = new ConfiguredFeaturedSelector(['999', '1', '1']);

    expect(ids(selector.select(sampleCatalogue(), 2))).toEqual(['1', '5']);
  });

  it('respects the limit even when more products are chosen', () => {
    const selector = new ConfiguredFeaturedSelector(['1', '2', '3', '4']);

    expect(ids(selector.select(sampleCatalogue(), 2))).toEqual(['1', '2']);
  });

  it('returns what exists when there are fewer candidates than the limit', () => {
    const selector = new ConfiguredFeaturedSelector([]);

    expect(selector.select(sampleCatalogue().slice(0, 2), 5)).toHaveLength(2);
  });
});

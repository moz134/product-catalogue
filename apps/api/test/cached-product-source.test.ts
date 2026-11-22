import { describe, expect, it, vi } from 'vitest';
import { CachedProductSource } from '../src/adapters/cache/cached-product-source.js';
import type { ProductSource } from '../src/ports/product-source.js';
import { makeProduct } from './fixtures.js';

function setup(ttlMs = 1000) {
  let now = 0;
  const inner = {
    listProducts: vi.fn(() => Promise.resolve([makeProduct()])),
    getProduct: vi.fn(() => Promise.resolve(null)),
    listCategories: vi.fn(() => Promise.resolve([])),
  } satisfies ProductSource;
  const cached = new CachedProductSource(inner, ttlMs, () => now);
  return { inner, cached, advance: (ms: number) => (now += ms) };
}

describe('CachedProductSource', () => {
  it('serves repeat calls from cache within the TTL', async () => {
    const { inner, cached, advance } = setup();

    await cached.listProducts();
    advance(999);
    await cached.listProducts();

    expect(inner.listProducts).toHaveBeenCalledTimes(1);
  });

  it('reloads after the TTL expires', async () => {
    const { inner, cached, advance } = setup();

    await cached.listProducts();
    advance(1001);
    await cached.listProducts();

    expect(inner.listProducts).toHaveBeenCalledTimes(2);
  });

  it('shares one upstream call between concurrent requests', async () => {
    const { inner, cached } = setup();

    await Promise.all([cached.listProducts(), cached.listProducts(), cached.listProducts()]);

    expect(inner.listProducts).toHaveBeenCalledTimes(1);
  });

  it('caches products per id', async () => {
    const { inner, cached } = setup();

    await cached.getProduct('1');
    await cached.getProduct('1');
    await cached.getProduct('2');

    expect(inner.getProduct).toHaveBeenCalledTimes(2);
  });

  it('does not cache failures', async () => {
    const { inner, cached } = setup();
    inner.listProducts.mockRejectedValueOnce(new Error('down'));

    await expect(cached.listProducts()).rejects.toThrow('down');
    await expect(cached.listProducts()).resolves.toHaveLength(1);
    expect(inner.listProducts).toHaveBeenCalledTimes(2);
  });

  it('passes straight through when the TTL is 0', async () => {
    const { inner, cached } = setup(0);

    await cached.listProducts();
    await cached.listProducts();

    expect(inner.listProducts).toHaveBeenCalledTimes(2);
  });
});

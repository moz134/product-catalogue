import type { Category, Product } from '../../domain/types.js';
import type { ProductSource } from '../../ports/product-source.js';

interface Entry<T> {
  expiresAt: number;
  value: Promise<T>;
}

/**
 * In-process TTL cache for any ProductSource. Concurrent requests for the same key share one
 * upstream call, and failures are not cached.
 */
export class CachedProductSource implements ProductSource {
  private readonly entries = new Map<string, Entry<unknown>>();

  constructor(
    private readonly inner: ProductSource,
    private readonly ttlMs: number,
    private readonly now: () => number = Date.now,
  ) {}

  listProducts(): Promise<Product[]> {
    return this.cached('products', () => this.inner.listProducts());
  }

  getProduct(id: string): Promise<Product | null> {
    return this.cached(`product:${id}`, () => this.inner.getProduct(id));
  }

  listCategories(): Promise<Category[]> {
    return this.cached('categories', () => this.inner.listCategories());
  }

  private cached<T>(key: string, load: () => Promise<T>): Promise<T> {
    if (this.ttlMs <= 0) return load();
    const existing = this.entries.get(key) as Entry<T> | undefined;
    if (existing && existing.expiresAt > this.now()) return existing.value;

    const value = load();
    this.entries.set(key, { expiresAt: this.now() + this.ttlMs, value });
    value.catch(() => {
      // Only evict if a newer request has not already replaced this entry.
      if (this.entries.get(key)?.value === value) this.entries.delete(key);
    });
    return value;
  }
}

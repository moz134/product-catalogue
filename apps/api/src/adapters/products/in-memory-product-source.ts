import type { Category, Product } from '../../domain/types.js';
import type { ProductSource } from '../../ports/product-source.js';

export class InMemoryProductSource implements ProductSource {
  constructor(private readonly products: readonly Product[]) {}

  listProducts(): Promise<Product[]> {
    return Promise.resolve([...this.products]);
  }

  getProduct(id: string): Promise<Product | null> {
    return Promise.resolve(this.products.find((p) => p.id === id) ?? null);
  }

  listCategories(): Promise<Category[]> {
    const bySlug = new Map<string, Category>();
    for (const { category } of this.products) bySlug.set(category.slug, category);
    return Promise.resolve([...bySlug.values()]);
  }
}

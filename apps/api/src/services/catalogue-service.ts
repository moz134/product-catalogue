import { NotFoundError } from '../domain/errors.js';
import type { Category, Product } from '../domain/types.js';
import type { FeaturedSelector } from '../ports/featured-selector.js';
import type { ProductSource } from '../ports/product-source.js';
import { searchProducts } from './search.js';

export interface CatalogueSettings {
  featuredCount: number;
  categoryTopRatedCount: number;
}

export interface CategoryPage {
  category: Category;
  topRated: Product[];
  others: Product[];
}

export class CatalogueService {
  constructor(
    private readonly source: ProductSource,
    private readonly featured: FeaturedSelector,
    private readonly settings: CatalogueSettings,
  ) {}

  async getFeaturedProducts(): Promise<Product[]> {
    const products = await this.source.listProducts();
    return this.featured.select(products, this.settings.featuredCount);
  }

  listCategories(): Promise<Category[]> {
    return this.source.listCategories();
  }

  async getCategoryPage(slug: string): Promise<CategoryPage> {
    const [categories, products] = await Promise.all([
      this.source.listCategories(),
      this.source.listProducts(),
    ]);
    const category = categories.find((c) => c.slug === slug);
    if (!category) throw new NotFoundError('Category', slug);

    const inCategory = products.filter((p) => p.category.slug === slug);
    const topRated = this.featured.select(inCategory, this.settings.categoryTopRatedCount);
    const others = inCategory.filter((p) => !topRated.includes(p));
    return { category, topRated, others };
  }

  async listProducts(search?: string): Promise<Product[]> {
    const products = await this.source.listProducts();
    return search === undefined ? products : searchProducts(products, search);
  }

  async getProduct(id: string): Promise<Product> {
    const product = await this.source.getProduct(id);
    if (!product) throw new NotFoundError('Product', id);
    return product;
  }
}

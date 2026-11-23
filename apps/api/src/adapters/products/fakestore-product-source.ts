import { z } from 'zod';
import { UpstreamError } from '../../domain/errors.js';
import { toDisplayName, toSlug } from '../../domain/slug.js';
import type { Category, Product } from '../../domain/types.js';
import type { ProductSource } from '../../ports/product-source.js';

// Validates Fake Store's payload and maps it to our Product shape; nothing outside this file knows its format.

const fakeStoreProductSchema = z.object({
  id: z.number().int(),
  title: z.string(),
  price: z.number(),
  description: z.string(),
  category: z.string(),
  image: z.url(),
  rating: z.object({ rate: z.number(), count: z.number() }).optional().default({ rate: 0, count: 0 }),
});
type FakeStoreProduct = z.infer<typeof fakeStoreProductSchema>;

export interface FakeStoreOptions {
  baseUrl: string;
  timeoutMs: number;
  currency: string;
  fetchFn?: typeof fetch;
}

export class FakeStoreProductSource implements ProductSource {
  private readonly baseUrl: string;
  private readonly fetchFn: typeof fetch;

  constructor(private readonly options: FakeStoreOptions) {
    this.baseUrl = options.baseUrl.replace(/\/+$/, '');
    this.fetchFn = options.fetchFn ?? fetch;
  }

  async listProducts(): Promise<Product[]> {
    const body = await this.getJson('/products');
    return this.parse(z.array(fakeStoreProductSchema), body, '/products').map((p) => this.toProduct(p));
  }

  async getProduct(id: string): Promise<Product | null> {
    // Fake Store ids are positive integers; anything else cannot exist.
    if (!/^[1-9]\d{0,9}$/.test(id)) return null;
    const body = await this.getJson(`/products/${id}`);
    // Fake Store answers 200 with an empty body for unknown ids.
    if (body === null) return null;
    return this.toProduct(this.parse(fakeStoreProductSchema, body, `/products/${id}`));
  }

  async listCategories(): Promise<Category[]> {
    const body = await this.getJson('/products/categories');
    return this.parse(z.array(z.string()), body, '/products/categories').map((name) => ({
      slug: toSlug(name),
      name: toDisplayName(name),
    }));
  }

  private toProduct(p: FakeStoreProduct): Product {
    return {
      id: String(p.id),
      title: p.title,
      description: p.description,
      price: { amount: p.price, currency: this.options.currency },
      imageUrl: p.image,
      category: { slug: toSlug(p.category), name: toDisplayName(p.category) },
      rating: {
        average: Math.min(5, Math.max(0, p.rating.rate)),
        count: Math.max(0, Math.round(p.rating.count)),
      },
    };
  }

  /** Returns parsed JSON, or null for an empty body. */
  private async getJson(path: string): Promise<unknown> {
    let response: Response;
    let text: string;
    try {
      // The timeout covers both the response headers and reading the body.
      response = await this.fetchFn(`${this.baseUrl}${path}`, {
        headers: { accept: 'application/json' },
        signal: AbortSignal.timeout(this.options.timeoutMs),
      });
      text = await response.text();
    } catch (cause) {
      throw new UpstreamError(`Product source request failed: GET ${path}`, { cause });
    }
    if (response.status === 404) return null;
    if (!response.ok) {
      throw new UpstreamError(`Product source responded ${response.status}: GET ${path}`);
    }
    if (text.trim() === '') return null;
    try {
      return JSON.parse(text) as unknown;
    } catch (cause) {
      throw new UpstreamError(`Product source returned invalid JSON: GET ${path}`, { cause });
    }
  }

  private parse<T>(schema: z.ZodType<T>, body: unknown, path: string): T {
    const result = schema.safeParse(body);
    if (!result.success) {
      throw new UpstreamError(`Product source returned an unexpected shape: GET ${path}`, {
        cause: result.error,
      });
    }
    return result.data;
  }
}

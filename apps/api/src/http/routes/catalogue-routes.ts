import {
  searchQuerySchema,
  type CategoryListResponse,
  type CategoryPageResponse,
  type Product,
  type ProductListResponse,
} from '@catalogue/shared';
import type { FastifyInstance, FastifyReply } from 'fastify';
import { z } from 'zod';
import type { CatalogueService } from '../../services/catalogue-service.js';
import { parseOrThrow } from '../validation.js';

const productParamsSchema = z.object({ id: z.string().trim().min(1).max(64) });
const categoryParamsSchema = z.object({
  slug: z.string().regex(/^[a-z0-9-]{1,64}$/, 'Invalid category'),
});

/** Catalogue data changes rarely, so clients and a future CDN may cache it briefly. */
function cacheable(reply: FastifyReply): void {
  void reply.header('cache-control', 'public, max-age=60');
}

export function registerCatalogueRoutes(app: FastifyInstance, catalogue: CatalogueService): void {
  app.get('/products/featured', async (_request, reply): Promise<ProductListResponse> => {
    cacheable(reply);
    return { items: await catalogue.getFeaturedProducts() };
  });

  app.get('/products', async (request, reply): Promise<ProductListResponse> => {
    const { search } = parseOrThrow(searchQuerySchema, request.query);
    cacheable(reply);
    return { items: await catalogue.listProducts(search) };
  });

  app.get('/products/:id', async (request, reply): Promise<Product> => {
    const { id } = parseOrThrow(productParamsSchema, request.params);
    cacheable(reply);
    return catalogue.getProduct(id);
  });

  app.get('/categories', async (_request, reply): Promise<CategoryListResponse> => {
    cacheable(reply);
    return { items: await catalogue.listCategories() };
  });

  app.get('/categories/:slug/products', async (request, reply): Promise<CategoryPageResponse> => {
    const { slug } = parseOrThrow(categoryParamsSchema, request.params);
    cacheable(reply);
    return catalogue.getCategoryPage(slug);
  });
}

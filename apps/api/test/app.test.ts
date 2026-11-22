import {
  apiErrorResponseSchema,
  categoryPageResponseSchema,
  enquiryResponseSchema,
  productListResponseSchema,
  productSchema,
} from '@catalogue/shared';
import type { FastifyInstance } from 'fastify';
import { afterEach, describe, expect, it } from 'vitest';
import { ConfiguredFeaturedSelector } from '../src/adapters/merchandising/configured-featured-selector.js';
import { InMemoryProductSource } from '../src/adapters/products/in-memory-product-source.js';
import { EmailDeliveryError, UpstreamError } from '../src/domain/errors.js';
import { buildApp } from '../src/http/app.js';
import type { EmailMessage, EmailSender } from '../src/ports/email-sender.js';
import type { ProductSource } from '../src/ports/product-source.js';
import { CatalogueService } from '../src/services/catalogue-service.js';
import { EnquiryService } from '../src/services/enquiry-service.js';
import { sampleCatalogue } from './fixtures.js';

class RecordingEmailSender implements EmailSender {
  sent: EmailMessage[] = [];
  failWith?: Error;
  send(message: EmailMessage) {
    if (this.failWith) return Promise.reject(this.failWith);
    this.sent.push(message);
    return Promise.resolve();
  }
}

const failingSource: ProductSource = {
  listProducts: () => Promise.reject(new UpstreamError('down')),
  getProduct: () => Promise.reject(new UpstreamError('down')),
  listCategories: () => Promise.reject(new UpstreamError('down')),
};

let app: FastifyInstance;

async function setup(options: { source?: ProductSource; rateLimit?: number } = {}) {
  const source = options.source ?? new InMemoryProductSource(sampleCatalogue());
  const email = new RecordingEmailSender();
  const featured = new ConfiguredFeaturedSelector(['7', '3', '1', '6', '4']);
  app = await buildApp(
    {
      catalogue: new CatalogueService(source, featured, { featuredCount: 5, categoryTopRatedCount: 2 }),
      enquiries: new EnquiryService(source, email, { salesInbox: 'sales@shop.test' }),
    },
    { enquiryRateLimitPerMinute: options.rateLimit ?? 100 },
  );
  return { app, email };
}

afterEach(async () => {
  await app?.close();
});

const ids = (products: { id: string }[]) => products.map((p) => p.id);

const validEnquiry = {
  productId: '2',
  name: 'Ada Lovelace',
  email: 'ada@example.com',
  message: 'Is this in stock?',
};

describe('GET /health', () => {
  it('reports ok', async () => {
    await setup();
    const res = await app.inject({ method: 'GET', url: '/health' });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ status: 'ok' });
  });
});

describe('Home page: GET /api/v1/products/featured', () => {
  it('returns the 5 chosen top-rated products', async () => {
    await setup();

    const res = await app.inject({ method: 'GET', url: '/api/v1/products/featured' });

    expect(res.statusCode).toBe(200);
    const body = productListResponseSchema.parse(res.json());
    expect(ids(body.items)).toEqual(['7', '3', '1', '6', '4']);
    expect(res.headers['cache-control']).toBe('public, max-age=60');
  });
});

describe('Category page', () => {
  it('lists categories', async () => {
    await setup();

    const res = await app.inject({ method: 'GET', url: '/api/v1/categories' });

    expect(res.json()).toEqual({
      items: [
        { slug: 'electronics', name: 'Electronics' },
        { slug: 'jewelery', name: 'Jewelery' },
      ],
    });
  });

  it('returns top-rated products for the category, then the rest of the category', async () => {
    await setup();

    const res = await app.inject({ method: 'GET', url: '/api/v1/categories/electronics/products' });

    expect(res.statusCode).toBe(200);
    const body = categoryPageResponseSchema.parse(res.json());
    expect(body.category).toEqual({ slug: 'electronics', name: 'Electronics' });
    // Chosen ids in this category are 3 and 1; limit is 2.
    expect(ids(body.topRated)).toEqual(['3', '1']);
    expect(ids(body.others)).toEqual(['2', '4']);
    expect([...body.topRated, ...body.others].every((p) => p.category.slug === 'electronics')).toBe(true);
  });

  it('returns 404 for an unknown category', async () => {
    await setup();

    const res = await app.inject({ method: 'GET', url: '/api/v1/categories/garden/products' });

    expect(res.statusCode).toBe(404);
    expect(apiErrorResponseSchema.parse(res.json()).error.code).toBe('NOT_FOUND');
  });

  it('returns 400 for a malformed category slug', async () => {
    await setup();

    const res = await app.inject({ method: 'GET', url: '/api/v1/categories/NOT%20VALID/products' });

    expect(res.statusCode).toBe(400);
  });
});

describe('Search: GET /api/v1/products?search=', () => {
  it('only returns products matching the search term', async () => {
    await setup();

    const res = await app.inject({ method: 'GET', url: '/api/v1/products?search=ssd' });

    expect(res.statusCode).toBe(200);
    expect(ids(productListResponseSchema.parse(res.json()).items)).toEqual(['2']);
  });

  it('returns an empty list when nothing matches', async () => {
    await setup();

    const res = await app.inject({ method: 'GET', url: '/api/v1/products?search=unicorn' });

    expect(res.json()).toEqual({ items: [] });
  });

  it('returns all products without a search term', async () => {
    await setup();

    const res = await app.inject({ method: 'GET', url: '/api/v1/products' });

    expect(productListResponseSchema.parse(res.json()).items).toHaveLength(7);
  });

  it('rejects blank and overly long search terms', async () => {
    await setup();

    const blank = await app.inject({ method: 'GET', url: '/api/v1/products?search=%20%20' });
    const long = await app.inject({ method: 'GET', url: `/api/v1/products?search=${'a'.repeat(101)}` });

    expect(blank.statusCode).toBe(400);
    expect(long.statusCode).toBe(400);
  });
});

describe('Product page: GET /api/v1/products/:id', () => {
  it('returns the product', async () => {
    await setup();

    const res = await app.inject({ method: 'GET', url: '/api/v1/products/5' });

    expect(res.statusCode).toBe(200);
    expect(productSchema.parse(res.json()).title).toBe('Gold ring');
  });

  it('returns 404 for an unknown product', async () => {
    await setup();

    const res = await app.inject({ method: 'GET', url: '/api/v1/products/999' });

    expect(res.statusCode).toBe(404);
    expect(res.json().error.code).toBe('NOT_FOUND');
  });
});

describe('Enquiry: POST /api/v1/enquiries', () => {
  it('emails the sales inbox and returns a reference', async () => {
    const { email } = await setup();

    const res = await app.inject({ method: 'POST', url: '/api/v1/enquiries', payload: validEnquiry });

    expect(res.statusCode).toBe(202);
    expect(enquiryResponseSchema.parse(res.json()).reference).toMatch(/^[0-9a-f-]{36}$/);
    expect(email.sent).toHaveLength(1);
    expect(email.sent[0]).toMatchObject({ to: 'sales@shop.test', replyTo: 'ada@example.com' });
  });

  it('returns field errors for invalid input and sends nothing', async () => {
    const { email } = await setup();

    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/enquiries',
      payload: { productId: '2', name: '', email: 'not-an-email' },
    });

    expect(res.statusCode).toBe(400);
    const body = apiErrorResponseSchema.parse(res.json());
    expect(body.error.code).toBe('VALIDATION_ERROR');
    expect(Object.keys(body.error.fields ?? {})).toEqual(expect.arrayContaining(['name', 'email']));
    expect(email.sent).toHaveLength(0);
  });

  it('returns 404 when the product does not exist', async () => {
    await setup();

    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/enquiries',
      payload: { ...validEnquiry, productId: '999' },
    });

    expect(res.statusCode).toBe(404);
  });

  it('returns 502 with a friendly message when email delivery fails', async () => {
    const { email } = await setup();
    email.failWith = new EmailDeliveryError('smtp down');

    const res = await app.inject({ method: 'POST', url: '/api/v1/enquiries', payload: validEnquiry });

    expect(res.statusCode).toBe(502);
    expect(res.json().error).toEqual({
      code: 'EMAIL_DELIVERY_FAILED',
      message: 'We could not send your enquiry. Please try again shortly.',
    });
  });

  it('rejects malformed JSON', async () => {
    await setup();

    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/enquiries',
      headers: { 'content-type': 'application/json' },
      payload: '{not json',
    });

    expect(res.statusCode).toBe(400);
    expect(res.json().error.code).toBe('VALIDATION_ERROR');
  });

  it('rate-limits repeated submissions', async () => {
    await setup({ rateLimit: 2 });

    const statuses: number[] = [];
    for (let i = 0; i < 3; i++) {
      const res = await app.inject({ method: 'POST', url: '/api/v1/enquiries', payload: validEnquiry });
      statuses.push(res.statusCode);
    }

    expect(statuses).toEqual([202, 202, 429]);
  });
});

describe('Errors and security', () => {
  it('returns 502 without leaking details when the product source is down', async () => {
    await setup({ source: failingSource });

    const res = await app.inject({ method: 'GET', url: '/api/v1/products/featured' });

    expect(res.statusCode).toBe(502);
    expect(res.json().error.code).toBe('UPSTREAM_UNAVAILABLE');
    expect(res.body).not.toContain('down');
  });

  it('returns a JSON 404 for unknown routes', async () => {
    await setup();

    const res = await app.inject({ method: 'GET', url: '/api/v1/nope' });

    expect(res.statusCode).toBe(404);
    expect(res.json().error.code).toBe('NOT_FOUND');
  });

  it('sets security headers', async () => {
    await setup();

    const res = await app.inject({ method: 'GET', url: '/health' });

    expect(res.headers['x-content-type-options']).toBe('nosniff');
  });
});

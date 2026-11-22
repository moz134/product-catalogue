import { describe, expect, it, vi } from 'vitest';
import { FakeStoreProductSource } from '../src/adapters/products/fakestore-product-source.js';
import { UpstreamError } from '../src/domain/errors.js';

const upstreamProduct = {
  id: 3,
  title: 'Mens Cotton Jacket',
  price: 55.99,
  description: 'Great outerwear',
  category: "men's clothing",
  image: 'https://fakestoreapi.com/img/3.jpg',
  rating: { rate: 4.7, count: 500 },
};

function sourceReturning(response: Response | Error) {
  const fetchFn = vi.fn<typeof fetch>(() =>
    response instanceof Error ? Promise.reject(response) : Promise.resolve(response),
  );
  const source = new FakeStoreProductSource({
    baseUrl: 'https://fake.test/',
    timeoutMs: 1000,
    currency: 'USD',
    fetchFn,
  });
  return { source, fetchFn };
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

describe('FakeStoreProductSource', () => {
  it('maps upstream products to our Product shape', async () => {
    const { source, fetchFn } = sourceReturning(json([upstreamProduct]));

    const products = await source.listProducts();

    expect(fetchFn).toHaveBeenCalledWith('https://fake.test/products', expect.anything());
    expect(products).toEqual([
      {
        id: '3',
        title: 'Mens Cotton Jacket',
        description: 'Great outerwear',
        price: { amount: 55.99, currency: 'USD' },
        imageUrl: 'https://fakestoreapi.com/img/3.jpg',
        category: { slug: 'mens-clothing', name: "Men's clothing" },
        rating: { average: 4.7, count: 500 },
      },
    ]);
  });

  it('maps categories to slug and display name', async () => {
    const { source } = sourceReturning(json(['electronics', "women's clothing"]));

    await expect(source.listCategories()).resolves.toEqual([
      { slug: 'electronics', name: 'Electronics' },
      { slug: 'womens-clothing', name: "Women's clothing" },
    ]);
  });

  it('returns null for an unknown product (Fake Store sends 200 with an empty body)', async () => {
    const { source } = sourceReturning(new Response('', { status: 200 }));

    await expect(source.getProduct('999')).resolves.toBeNull();
  });

  it('returns null without calling upstream for ids Fake Store cannot have', async () => {
    const { source, fetchFn } = sourceReturning(json(upstreamProduct));

    await expect(source.getProduct('../admin')).resolves.toBeNull();
    expect(fetchFn).not.toHaveBeenCalled();
  });

  it('throws UpstreamError on a server error', async () => {
    const { source } = sourceReturning(new Response('oops', { status: 503 }));

    await expect(source.listProducts()).rejects.toBeInstanceOf(UpstreamError);
  });

  it('throws UpstreamError on a network failure or timeout', async () => {
    const { source } = sourceReturning(new TypeError('fetch failed'));

    await expect(source.listProducts()).rejects.toBeInstanceOf(UpstreamError);
  });

  it('throws UpstreamError when upstream changes shape', async () => {
    const { source } = sourceReturning(json([{ id: 'not-a-number', title: 1 }]));

    await expect(source.listProducts()).rejects.toBeInstanceOf(UpstreamError);
  });
});

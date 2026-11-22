import type { Product } from '@catalogue/shared';

let nextId = 1;

export function makeProduct(overrides: Partial<Product> = {}): Product {
  const id = overrides.id ?? String(nextId++);
  return {
    id,
    title: `Product ${id}`,
    description: `Description of product ${id}`,
    price: { amount: 10, currency: 'USD' },
    imageUrl: `https://images.example.com/${id}.png`,
    category: { slug: 'electronics', name: 'Electronics' },
    rating: { average: 3, count: 10 },
    ...overrides,
  };
}

export const electronics = { slug: 'electronics', name: 'Electronics' };
export const jewelery = { slug: 'jewelery', name: 'Jewelery' };

export function sampleCatalogue(): Product[] {
  return [
    makeProduct({
      id: '1',
      title: 'Laptop backpack',
      category: electronics,
      rating: { average: 3.9, count: 120 },
    }),
    makeProduct({
      id: '2',
      title: 'SSD drive 1TB',
      category: electronics,
      rating: { average: 4.8, count: 300 },
    }),
    makeProduct({
      id: '3',
      title: 'USB cable',
      description: 'Fast charging',
      category: electronics,
      rating: { average: 2.1, count: 50 },
    }),
    makeProduct({
      id: '4',
      title: 'Monitor 27in',
      category: electronics,
      rating: { average: 4.5, count: 80 },
    }),
    makeProduct({ id: '5', title: 'Gold ring', category: jewelery, rating: { average: 4.9, count: 20 } }),
    makeProduct({
      id: '6',
      title: 'Silver necklace',
      description: 'Pairs well with a backpack',
      category: jewelery,
      rating: { average: 1.5, count: 5 },
    }),
    makeProduct({
      id: '7',
      title: 'Pearl earrings',
      category: jewelery,
      rating: { average: 4.0, count: 40 },
    }),
  ];
}

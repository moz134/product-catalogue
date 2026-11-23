import {
  apiErrorResponseSchema,
  categoryListResponseSchema,
  categoryPageResponseSchema,
  enquiryRequestSchema,
  enquiryResponseSchema,
  productListResponseSchema,
  productSchema,
} from '@catalogue/shared';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import type { z } from 'zod';

// The iOS tests decode the same fixtures (ContractFixtureTests.swift).
const fixturesDir = join(import.meta.dirname, '../../../packages/shared/fixtures');

const schemaFor: Record<string, z.ZodType> = {
  'product.json': productSchema,
  'product-list.json': productListResponseSchema,
  'category-list.json': categoryListResponseSchema,
  'category-page.json': categoryPageResponseSchema,
  'enquiry-request.json': enquiryRequestSchema,
  'enquiry-response.json': enquiryResponseSchema,
  'error-validation.json': apiErrorResponseSchema,
  'error-not-found.json': apiErrorResponseSchema,
};

describe('contract fixtures', () => {
  const files = readdirSync(fixturesDir).filter((file) => file.endsWith('.json'));

  it('every fixture has a schema (no untested fixtures)', () => {
    expect(files.sort()).toEqual(Object.keys(schemaFor).sort());
  });

  it.each(Object.entries(schemaFor))('%s matches the contract exactly', (file, schema) => {
    const raw: unknown = JSON.parse(readFileSync(join(fixturesDir, file), 'utf8'));
    const result = schema.safeParse(raw);
    expect(result.error?.issues).toBeUndefined();
    // Parsed output must equal input: catches fields the schema would silently drop.
    expect(result.data).toEqual(raw);
  });
});

import { describe, expect, it } from 'vitest';
import { loadConfig } from '../src/config.js';

describe('loadConfig', () => {
  it('has working defaults with an empty environment', () => {
    const config = loadConfig({});

    expect(config.PORT).toBe(3000);
    expect(config.EMAIL_PROVIDER).toBe('console');
    expect(config.FEATURED_PRODUCT_IDS).toEqual([]);
    expect(config.FEATURED_COUNT).toBe(5);
  });

  it('parses lists, numbers and booleans, treating empty strings as unset', () => {
    const config = loadConfig({
      FEATURED_PRODUCT_IDS: ' 1, 5 ,,9 ',
      PORT: '8080',
      TRUST_PROXY: 'true',
      SMTP_USER: '',
    });

    expect(config.FEATURED_PRODUCT_IDS).toEqual(['1', '5', '9']);
    expect(config.PORT).toBe(8080);
    expect(config.TRUST_PROXY).toBe(true);
    expect(config.SMTP_USER).toBeUndefined();
  });

  it('fails fast with a readable message on invalid values', () => {
    expect(() => loadConfig({ SALES_INBOX_EMAIL: 'not-an-email', EMAIL_PROVIDER: 'pigeon' })).toThrow(
      /SALES_INBOX_EMAIL[\s\S]*EMAIL_PROVIDER|EMAIL_PROVIDER[\s\S]*SALES_INBOX_EMAIL/,
    );
  });
});

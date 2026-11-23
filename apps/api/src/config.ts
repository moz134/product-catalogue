import { z } from 'zod';

// Every value has a local default so the app runs without a .env file (documented in .env.example).

const booleanFromEnv = z.enum(['true', 'false']).transform((value) => value === 'true');

const idListFromEnv = z.string().transform((value) =>
  value
    .split(',')
    .map((id) => id.trim())
    .filter((id) => id.length > 0),
);

const configSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  HOST: z.string().default('0.0.0.0'),
  PORT: z.coerce.number().int().positive().default(3000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  /** Set behind a reverse proxy or load balancer so client IPs (used for rate limiting) are correct. */
  TRUST_PROXY: booleanFromEnv.default(false),

  PRODUCT_SOURCE: z.enum(['fakestore']).default('fakestore'),
  FAKESTORE_BASE_URL: z.url().default('https://fakestoreapi.com'),
  UPSTREAM_TIMEOUT_MS: z.coerce.number().int().positive().default(5000),
  PRODUCT_CACHE_TTL_SECONDS: z.coerce.number().int().nonnegative().default(300),
  CURRENCY: z.string().length(3).default('USD'),

  FEATURED_PRODUCT_IDS: idListFromEnv.default([]),
  FEATURED_COUNT: z.coerce.number().int().positive().default(5),
  CATEGORY_TOP_RATED_COUNT: z.coerce.number().int().positive().default(3),

  EMAIL_PROVIDER: z.enum(['smtp', 'console']).default('console'),
  SMTP_HOST: z.string().default('localhost'),
  SMTP_PORT: z.coerce.number().int().positive().default(1025),
  SMTP_SECURE: booleanFromEnv.default(false),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  SALES_INBOX_EMAIL: z.email().default('sales@example.com'),
  ENQUIRY_FROM_EMAIL: z.email().default('no-reply@example.com'),

  ENQUIRY_RATE_LIMIT_PER_MINUTE: z.coerce.number().int().positive().default(5),
});

export type Config = z.infer<typeof configSchema>;

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  // Treat empty strings as "not set" so `FOO=` in a .env file falls back to the default.
  const cleaned = Object.fromEntries(
    Object.entries(env).filter(([, value]) => value !== undefined && value !== ''),
  );
  const result = configSchema.safeParse(cleaned);
  if (!result.success) {
    const problems = result.error.issues
      .map((issue) => `  - ${issue.path.join('.')}: ${issue.message}`)
      .join('\n');
    throw new Error(`Invalid configuration:\n${problems}`);
  }
  return result.data;
}

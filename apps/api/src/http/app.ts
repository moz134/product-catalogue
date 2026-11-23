import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import Fastify, { type FastifyBaseLogger, type FastifyInstance } from 'fastify';
import type { CatalogueService } from '../services/catalogue-service.js';
import type { EnquiryService } from '../services/enquiry-service.js';
import { registerErrorHandling } from './error-handler.js';
import { registerCatalogueRoutes } from './routes/catalogue-routes.js';
import { registerEnquiryRoutes } from './routes/enquiry-routes.js';

export interface AppServices {
  catalogue: CatalogueService;
  enquiries: EnquiryService;
}

export interface AppOptions {
  /** Omit to disable request logging (tests). */
  logger?: FastifyBaseLogger;
  trustProxy?: boolean;
  enquiryRateLimitPerMinute: number;
}

export async function buildApp(services: AppServices, options: AppOptions): Promise<FastifyInstance> {
  const app = Fastify({
    ...(options.logger ? { loggerInstance: options.logger } : { logger: false }),
    trustProxy: options.trustProxy ?? false,
    bodyLimit: 16 * 1024,
    requestIdHeader: 'x-request-id',
  });

  await app.register(helmet);
  await app.register(rateLimit, { global: false });
  registerErrorHandling(app);

  app.get('/health', () => ({ status: 'ok' }));

  await app.register(
    (api, _opts, done) => {
      registerCatalogueRoutes(api, services.catalogue);
      registerEnquiryRoutes(api, services.enquiries, {
        ratePerMinute: options.enquiryRateLimitPerMinute,
      });
      done();
    },
    { prefix: '/api/v1' },
  );

  return app;
}

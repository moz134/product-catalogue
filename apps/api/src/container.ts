import { CachedProductSource } from './adapters/cache/cached-product-source.js';
import { ConsoleEmailSender, type MinimalLogger } from './adapters/email/console-email-sender.js';
import { SmtpEmailSender } from './adapters/email/smtp-email-sender.js';
import { ConfiguredFeaturedSelector } from './adapters/merchandising/configured-featured-selector.js';
import { FakeStoreProductSource } from './adapters/products/fakestore-product-source.js';
import type { Config } from './config.js';
import type { AppServices } from './http/app.js';
import type { EmailSender } from './ports/email-sender.js';
import type { ProductSource } from './ports/product-source.js';
import { CatalogueService } from './services/catalogue-service.js';
import { EnquiryService } from './services/enquiry-service.js';

// Composition root: the only place that chooses concrete adapters.

function createProductSource(config: Config): ProductSource {
  switch (config.PRODUCT_SOURCE) {
    case 'fakestore':
      return new FakeStoreProductSource({
        baseUrl: config.FAKESTORE_BASE_URL,
        timeoutMs: config.UPSTREAM_TIMEOUT_MS,
        currency: config.CURRENCY,
      });
  }
}

function createEmailSender(config: Config, logger: MinimalLogger): EmailSender {
  switch (config.EMAIL_PROVIDER) {
    case 'smtp':
      return new SmtpEmailSender({
        host: config.SMTP_HOST,
        port: config.SMTP_PORT,
        secure: config.SMTP_SECURE,
        user: config.SMTP_USER,
        pass: config.SMTP_PASS,
        from: config.ENQUIRY_FROM_EMAIL,
      });
    case 'console':
      return new ConsoleEmailSender(logger);
  }
}

export function createServices(config: Config, logger: MinimalLogger): AppServices {
  const source = new CachedProductSource(
    createProductSource(config),
    config.PRODUCT_CACHE_TTL_SECONDS * 1000,
  );
  const featured = new ConfiguredFeaturedSelector(config.FEATURED_PRODUCT_IDS);

  return {
    catalogue: new CatalogueService(source, featured, {
      featuredCount: config.FEATURED_COUNT,
      categoryTopRatedCount: config.CATEGORY_TOP_RATED_COUNT,
    }),
    enquiries: new EnquiryService(source, createEmailSender(config, logger), {
      salesInbox: config.SALES_INBOX_EMAIL,
    }),
  };
}

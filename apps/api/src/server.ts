import { pino } from 'pino';
import { loadConfig } from './config.js';
import { createServices } from './container.js';
import { buildApp } from './http/app.js';

const config = loadConfig();

const logger = pino({
  level: config.LOG_LEVEL,
  redact: ['req.headers.authorization', 'req.headers.cookie'],
  ...(config.NODE_ENV === 'development' ? { transport: { target: 'pino-pretty' } } : {}),
});

if (config.EMAIL_PROVIDER === 'console' && config.NODE_ENV === 'production') {
  logger.warn('EMAIL_PROVIDER=console in production: enquiries will be logged, not emailed');
}

const app = await buildApp(createServices(config, logger), {
  logger,
  trustProxy: config.TRUST_PROXY,
  enquiryRateLimitPerMinute: config.ENQUIRY_RATE_LIMIT_PER_MINUTE,
});

const shutdown = async (signal: string) => {
  app.log.info({ signal }, 'Shutting down');
  await app.close();
  process.exit(0);
};
process.once('SIGTERM', () => void shutdown('SIGTERM'));
process.once('SIGINT', () => void shutdown('SIGINT'));

try {
  await app.listen({ host: config.HOST, port: config.PORT });
} catch (error) {
  app.log.fatal({ err: error }, 'Failed to start');
  process.exit(1);
}

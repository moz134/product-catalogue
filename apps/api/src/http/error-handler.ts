import type { ApiErrorResponse, ErrorCode } from '@catalogue/shared';
import type { FastifyError, FastifyInstance } from 'fastify';
import { EmailDeliveryError, NotFoundError, UpstreamError } from '../domain/errors.js';
import { RequestValidationError } from './validation.js';

function body(code: ErrorCode, message: string, fields?: Record<string, string[]>): ApiErrorResponse {
  return { error: fields ? { code, message, fields } : { code, message } };
}

// The only place errors become HTTP responses. Internal details are logged, never returned.
export function registerErrorHandling(app: FastifyInstance): void {
  app.setNotFoundHandler((_request, reply) => {
    void reply.status(404).send(body('NOT_FOUND', 'Route not found'));
  });

  app.setErrorHandler((error: FastifyError, request, reply) => {
    if (error instanceof RequestValidationError) {
      return reply.status(400).send(body('VALIDATION_ERROR', error.message, error.fields));
    }
    if (error instanceof NotFoundError) {
      return reply.status(404).send(body('NOT_FOUND', error.message));
    }
    if (error instanceof UpstreamError) {
      request.log.error({ err: error }, 'Product source failure');
      return reply
        .status(502)
        .send(
          body('UPSTREAM_UNAVAILABLE', 'Products are temporarily unavailable. Please try again shortly.'),
        );
    }
    if (error instanceof EmailDeliveryError) {
      request.log.error({ err: error }, 'Email delivery failure');
      return reply
        .status(502)
        .send(body('EMAIL_DELIVERY_FAILED', 'We could not send your enquiry. Please try again shortly.'));
    }
    if (error.statusCode === 429) {
      return reply
        .status(429)
        .send(body('RATE_LIMITED', 'Too many requests. Please wait a minute and try again.'));
    }
    // Framework-level client errors: malformed JSON, wrong content type, body too large...
    if (error.statusCode !== undefined && error.statusCode >= 400 && error.statusCode < 500) {
      return reply.status(error.statusCode).send(body('VALIDATION_ERROR', error.message));
    }

    request.log.error({ err: error }, 'Unhandled error');
    return reply.status(500).send(body('INTERNAL_ERROR', 'Something went wrong. Please try again.'));
  });
}

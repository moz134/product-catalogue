import { enquiryRequestSchema, type EnquiryResponse } from '@catalogue/shared';
import type { FastifyInstance } from 'fastify';
import type { EnquiryService } from '../../services/enquiry-service.js';
import { parseOrThrow } from '../validation.js';

export interface EnquiryRouteOptions {
  ratePerMinute: number;
}

export function registerEnquiryRoutes(
  app: FastifyInstance,
  enquiries: EnquiryService,
  options: EnquiryRouteOptions,
): void {
  app.post(
    '/enquiries',
    { config: { rateLimit: { max: options.ratePerMinute, timeWindow: '1 minute' } } },
    async (request, reply): Promise<EnquiryResponse> => {
      const enquiry = parseOrThrow(enquiryRequestSchema, request.body);
      const { reference } = await enquiries.submit(enquiry);
      request.log.info({ reference, productId: enquiry.productId }, 'Enquiry sent');
      void reply.status(202);
      return { reference };
    },
  );
}

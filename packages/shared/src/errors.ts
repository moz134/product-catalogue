import { z } from 'zod';

export const errorCodes = [
  'VALIDATION_ERROR',
  'NOT_FOUND',
  'RATE_LIMITED',
  'UPSTREAM_UNAVAILABLE',
  'EMAIL_DELIVERY_FAILED',
  'INTERNAL_ERROR',
] as const;
export type ErrorCode = (typeof errorCodes)[number];

/** Every non-2xx response from the API has this shape. */
export const apiErrorResponseSchema = z.object({
  error: z.object({
    code: z.enum(errorCodes),
    message: z.string(),
    /** Field-level messages for VALIDATION_ERROR, keyed by field name. */
    fields: z.record(z.string(), z.array(z.string())).optional(),
  }),
});
export type ApiErrorResponse = z.infer<typeof apiErrorResponseSchema>;

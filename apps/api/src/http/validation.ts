import { z } from 'zod';

export class RequestValidationError extends Error {
  constructor(readonly fields: Record<string, string[]>) {
    super('The request is invalid');
    this.name = 'RequestValidationError';
  }
}

export function parseOrThrow<T>(schema: z.ZodType<T>, value: unknown): T {
  const result = schema.safeParse(value);
  if (!result.success) {
    const { fieldErrors, formErrors } = z.flattenError(result.error);
    const fields: Record<string, string[]> = {};
    for (const [key, messages] of Object.entries(fieldErrors)) {
      if (Array.isArray(messages) && messages.length > 0) fields[key] = messages as string[];
    }
    if (formErrors.length > 0) fields._ = formErrors;
    throw new RequestValidationError(fields);
  }
  return result.data;
}

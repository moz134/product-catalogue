import { z } from 'zod';

// The iOS app mirrors these rules and messages in EnquiryValidator.swift.
export const enquiryRequestSchema = z.object({
  productId: z.string().trim().min(1, 'Product is required'),
  name: z.string().trim().min(1, 'Please enter your name').max(100, 'Name is too long'),
  email: z
    .string()
    .trim()
    .min(1, 'Please enter your email')
    .email('Please enter a valid email address')
    .max(254, 'Email is too long'),
  phone: z
    .string()
    .trim()
    .max(30, 'Phone number is too long')
    .regex(/^[0-9 +()-]*$/, 'Phone number can only contain digits, spaces and + ( ) -')
    .optional()
    .or(z.literal('')),
  message: z.string().trim().max(2000, 'Message is too long').optional().or(z.literal('')),
});
export type EnquiryRequest = z.infer<typeof enquiryRequestSchema>;

export const enquiryResponseSchema = z.object({
  reference: z.string(),
});
export type EnquiryResponse = z.infer<typeof enquiryResponseSchema>;

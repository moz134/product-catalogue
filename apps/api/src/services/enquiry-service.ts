import { randomUUID } from 'node:crypto';
import type { EnquiryRequest } from '@catalogue/shared';
import { NotFoundError } from '../domain/errors.js';
import type { Product } from '../domain/types.js';
import type { EmailMessage, EmailSender } from '../ports/email-sender.js';
import type { ProductSource } from '../ports/product-source.js';
import { escapeHtml, singleLine } from './html.js';

export interface EnquirySettings {
  salesInbox: string;
}

export interface EnquiryResult {
  reference: string;
}

// The customer's address is the Reply-To, so sales can answer the email directly.
export class EnquiryService {
  constructor(
    private readonly source: ProductSource,
    private readonly email: EmailSender,
    private readonly settings: EnquirySettings,
    private readonly newReference: () => string = () => randomUUID(),
  ) {}

  async submit(request: EnquiryRequest): Promise<EnquiryResult> {
    const product = await this.source.getProduct(request.productId);
    if (!product) throw new NotFoundError('Product', request.productId);

    const reference = this.newReference();
    await this.email.send(buildSalesEmail(this.settings.salesInbox, reference, request, product));
    return { reference };
  }
}

export function buildSalesEmail(
  to: string,
  reference: string,
  request: EnquiryRequest,
  product: Product,
): EmailMessage {
  const rows: [string, string][] = [
    ['Reference', reference],
    ['Product', `${product.title} (ID ${product.id})`],
    ['Price', `${product.price.amount.toFixed(2)} ${product.price.currency}`],
    ['Name', request.name],
    ['Email', request.email],
    ['Phone', request.phone || '—'],
    ['Message', request.message || '—'],
  ];

  const text = ['New product enquiry', '', ...rows.map(([label, value]) => `${label}: ${value}`)].join('\n');

  const html = `<!doctype html>
<html><body style="font-family: sans-serif">
<h2>New product enquiry</h2>
<table cellpadding="6" style="border-collapse: collapse">
${rows
  .map(
    ([label, value]) =>
      `<tr><th align="left" valign="top">${escapeHtml(label)}</th><td style="white-space: pre-wrap">${escapeHtml(value)}</td></tr>`,
  )
  .join('\n')}
</table>
</body></html>`;

  return {
    to,
    replyTo: request.email,
    subject: singleLine(`New enquiry: ${product.title} from ${request.name}`),
    text,
    html,
  };
}

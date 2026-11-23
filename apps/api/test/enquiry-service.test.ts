import type { EnquiryRequest } from '@catalogue/shared';
import { describe, expect, it } from 'vitest';
import { InMemoryProductSource } from '../src/adapters/products/in-memory-product-source.js';
import { NotFoundError } from '../src/domain/errors.js';
import type { EmailMessage, EmailSender } from '../src/ports/email-sender.js';
import { EnquiryService } from '../src/services/enquiry-service.js';
import { makeProduct } from './fixtures.js';

class RecordingEmailSender implements EmailSender {
  sent: EmailMessage[] = [];
  send(message: EmailMessage) {
    this.sent.push(message);
    return Promise.resolve();
  }
}

function setup() {
  const email = new RecordingEmailSender();
  const product = makeProduct({ id: '42', title: 'Leather bag', price: { amount: 99.5, currency: 'USD' } });
  const service = new EnquiryService(
    new InMemoryProductSource([product]),
    email,
    { salesInbox: 'sales@shop.test' },
    () => 'ref-123',
  );
  return { service, email };
}

const enquiry: EnquiryRequest = {
  productId: '42',
  name: 'Ada Lovelace',
  email: 'ada@example.com',
  phone: '+44 20 1234 5678',
  message: 'Do you ship to Leeds?',
};

describe('EnquiryService', () => {
  it('emails the sales inbox with the enquiry and product details', async () => {
    const { service, email } = setup();

    const result = await service.submit(enquiry);

    expect(result).toEqual({ reference: 'ref-123' });
    expect(email.sent).toHaveLength(1);
    const [message] = email.sent;
    expect(message).toMatchObject({
      to: 'sales@shop.test',
      replyTo: 'ada@example.com',
      subject: 'New enquiry: Leather bag from Ada Lovelace',
    });
    for (const expected of [
      'ref-123',
      'Leather bag (ID 42)',
      '99.50 USD',
      'Ada Lovelace',
      'ada@example.com',
      '+44 20 1234 5678',
      'Do you ship to Leeds?',
    ]) {
      expect(message?.text).toContain(expected);
      expect(message?.html).toContain(expected);
    }
  });

  it('escapes customer input in the HTML email and keeps the subject on one line', async () => {
    const { service, email } = setup();

    await service.submit({ ...enquiry, name: 'Eve\r\nBcc: x@y.z', message: '<script>alert(1)</script>' });

    const [message] = email.sent;
    expect(message?.html).not.toContain('<script>');
    expect(message?.html).toContain('&lt;script&gt;alert(1)&lt;/script&gt;');
    expect(message?.subject).not.toMatch(/[\r\n]/);
  });

  it('rejects enquiries for products that do not exist', async () => {
    const { service, email } = setup();

    await expect(service.submit({ ...enquiry, productId: 'nope' })).rejects.toBeInstanceOf(NotFoundError);
    expect(email.sent).toHaveLength(0);
  });
});

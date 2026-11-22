import type { Transporter } from 'nodemailer';
import { describe, expect, it, vi } from 'vitest';
import { SmtpEmailSender } from '../src/adapters/email/smtp-email-sender.js';
import { EmailDeliveryError } from '../src/domain/errors.js';

const options = { host: 'smtp.test', port: 1025, secure: false, from: 'no-reply@shop.test' };
const message = {
  to: 'sales@shop.test',
  replyTo: 'ada@example.com',
  subject: 'Hi',
  text: 'Hi',
  html: '<p>Hi</p>',
};

describe('SmtpEmailSender', () => {
  it('sends from the configured address', async () => {
    const sendMail = vi.fn().mockResolvedValue({});
    const sender = new SmtpEmailSender(options, { sendMail } as unknown as Transporter);

    await sender.send(message);

    expect(sendMail).toHaveBeenCalledWith({ from: 'no-reply@shop.test', ...message });
  });

  it('wraps transport failures in EmailDeliveryError', async () => {
    const sendMail = vi.fn().mockRejectedValue(new Error('ECONNREFUSED'));
    const sender = new SmtpEmailSender(options, { sendMail } as unknown as Transporter);

    await expect(sender.send(message)).rejects.toBeInstanceOf(EmailDeliveryError);
  });
});

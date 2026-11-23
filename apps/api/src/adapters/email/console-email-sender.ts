import type { EmailMessage, EmailSender } from '../../ports/email-sender.js';

export interface MinimalLogger {
  info(obj: object, msg?: string): void;
}

// Development only: logs the email instead of sending it, including customer contact details.
export class ConsoleEmailSender implements EmailSender {
  constructor(private readonly logger: MinimalLogger) {}

  send(message: EmailMessage): Promise<void> {
    this.logger.info(
      { email: { to: message.to, replyTo: message.replyTo, subject: message.subject, text: message.text } },
      'Email (console provider, not actually sent)',
    );
    return Promise.resolve();
  }
}

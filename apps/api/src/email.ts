// Outgoing email through Cloudflare Email Service (`send_email` binding EMAIL): sign-in codes and support messages.
// Off until the sending domain is set up and EMAIL_FROM is set (e.g. "hello@yourdomain.com").

export function emailConfigured(env: Env): boolean {
  return Boolean(env.EMAIL_FROM) && typeof env.EMAIL?.send === "function";
}

export interface OutgoingEmail {
  to: string;
  subject: string;
  text: string;
  html?: string;
  replyTo?: string;
}

/** Sends one email. Throws if email isn't configured or Cloudflare refuses it (the caller decides what to tell the user). */
export async function sendEmail(env: Env, message: OutgoingEmail): Promise<string> {
  if (!emailConfigured(env)) throw new Error("Email isn't configured (EMAIL_FROM / send_email binding)");
  const result = await env.EMAIL.send({
    from: { email: env.EMAIL_FROM, name: "Her Crown" },
    to: message.to,
    subject: message.subject,
    text: message.text,
    ...(message.html ? { html: message.html } : {}),
    ...(message.replyTo ? { replyTo: message.replyTo } : {}),
  });
  return result.messageId;
}

export const escapeHtml = (s: string) => s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);

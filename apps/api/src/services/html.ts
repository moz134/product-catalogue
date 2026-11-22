const replacements: Record<string, string> = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
};

export function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (char) => replacements[char] ?? char);
}

/** Prevents header injection when untrusted text goes into a single-line field such as a subject. */
export function singleLine(value: string): string {
  return value.replace(/[\r\n]+/g, ' ').trim();
}
